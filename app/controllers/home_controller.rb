class HomeController < ApplicationController
  before_action :noindex_meta_tag

  def show
    if current_group.blank?
      if request.subdomain.present?
        respond_to_html_only do
          redirect_to root_url(subdomain: nil)
        end and return
      else
        redirect_to parties_path and return
      end
    elsif current_group.open_square?
      params[:sort] ||= 'hottest'
      @issues = search_and_sort_issues(Group.open_square.issues.deprecated_not_private_blocked(current_user), params[:keyword], params[:sort], 3)
      render 'home/group_home_open_square'
    else
      if current_group.private_blocked? current_user
        render 'home/group_home_private_blocked' and return
      end


      @issues = home_group_issues(current_group)
      @hot_issues = @issues.first(10)

      cached_discussions = Rails.cache.fetch("#{current_group.cache_key_with_version}/discussion_post_ids", expires_in: 1.hours) do
        discussions_all = Post.of_group(current_group).having_poll.or(Post.having_survey).or(Post.where.not(decision: nil))
        discussions_all = discussions_all.order_by_stroked_at
        discussions_fresh = discussions_all.after(2.weeks.ago, field: 'posts.last_stroked_at')

        cached_discussions = if discussions_fresh.any? and discussions_fresh.count < 3
          discussions_all.limit(30)
        else
          discussions_fresh
        end
        cached_discussions.select(:id).to_a
      end

      discussions_all = Post.having_poll.or(Post.having_survey)
      discussions_all = discussions_all.deprecated_not_private_blocked_of_group(current_group, current_user).unblinded(current_user)
      @discussion_posts_any = discussions_all.any?

      render 'home/group_home'
    end
  end

  def noindex_meta_tag
    if current_group.present? and current_group.private?
      set_meta_tags noindex: true
      return
    end

    if @issue.present? and @issue.private?
      set_meta_tags noindex: true
      return
    end
  end

  def group_home_all_posts
    how_to = params[:sort] == 'order_by_stroked_at' ? :order_by_stroked_at : :hottest

    @recent_posts = Post.unblinded(current_user).send(how_to)
    @recent_posts = @recent_posts.deprecated_not_private_blocked_of_group(current_group, current_user).unblinded(current_user)
    @recent_posts = @recent_posts.page(params[:page]).per(30)
  end

  def group_home_discussion_posts
    discussions_all = Post.having_poll.or(Post.having_survey)
    discussions_all = discussions_all.deprecated_not_private_blocked_of_group(current_group, current_user).unblinded(current_user)
    discussions_all = discussions_all.order_by_stroked_at
    discussions_fresh = discussions_all.after(2.weeks.ago, field: 'posts.last_stroked_at')

    if discussions_fresh.count > 3
      @discussion_posts = discussions_fresh.limit(9)
    else
      @discussion_posts = discussions_all.limit(9)
    end
  end

  private

  def search_and_sort_issues(issues, keyword, sort, item_a_row = 4)
    tags = (keyword.try(:split) || []).map(&:strip).reject(&:blank?)
    result = issues
    result = result.where(id: Issue.tagged_with(tags, any: true).except(:select).select(:id).union(Issue.search_for((smart_search_keyword(keyword))).select(:id))) if keyword.present?
    result = result.alive

    case sort
    when 'recent'
      result = result.recent
    when 'name'
      result = result.sort_by_name
    when 'recent_touched'
      result = result.recent_touched
    else
      result = result.hottest
    end

    result = result.categorized_with(params[:category_id]) if params[:category_id].present?
    result = result.page(params[:page]).per(item_a_row * 10)
    result
  end

  def home_group_issues(group)
    issues = Issue.displayable_in_current_group(group)
    issues = issues.alive
    issues = issues.to_a.reject { |issue| private_blocked?(issue) and !issue.listable_even_private? }
    issues
  end

  def private_blocked?(issue)
    issue.private_blocked?(current_user) and !current_user.try(:admin?)
  end
end