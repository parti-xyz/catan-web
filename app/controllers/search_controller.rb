class SearchController < ApplicationController
  def show
    if params[:nav_q].present?
      @search_type = params[:search_type]
      if @search_type.blank?
        @search_type = 'group' if params[:group_id].present?
        @search_type = 'issue' if params[:issue_id].present?
      end

      if @search_type == 'issue'
        issue = Issue.find_by(id: params[:issue_id])
        render_404 and return if issue.blank?
        redirect_to smart_issue_home_url(issue, nav_q: params[:nav_q]) and return
      end

      if @search_type == 'group'
        if params[:group_id].present?
          @current_search_group = Group.find_by(id: params[:group_id])
        end
        render_404 and return if @current_search_group.blank?

        if current_group != @current_search_group
          redirect_to search_url(subdomain: @current_search_group.subdomain, group_id: params[:group_id], search_type: params[:search_type], nav_q: params[:nav_q]) and return
        end
      end

      @search_q = PostSearchableIndex.sanitize_search_key params[:nav_q]
      if @search_q.blank?
        return
      end

      @groups = search_and_sort_groups(@search_q, @current_search_group)

      base_issues = search_and_sort_issues(@search_q, @current_search_group, 21)
      @issues = base_issues.to_a[0..20]
      @more_issues = base_issues.length >= 21

      base_posts = Post.of_searchable_issues(current_user)
      base_posts = base_posts.of_group(@current_search_group) if @current_search_group.present?
      base_posts = base_posts.order(last_stroked_at: :desc)
      base_posts = base_posts.search(@search_q) if @search_q.present?
      if view_context.is_infinite_scrollable?
        if request.format.js?
          @previous_last_post = Post.with_deleted.find_by(id: params[:last_id])
          limit_count = (@previous_last_post.blank? ? 10 : 20)
          @posts = base_posts.limit(limit_count).previous_of_post(@previous_last_post)

          current_last_post = @posts.last
          @is_last_page = (base_posts.empty? or base_posts.previous_of_post(current_last_post).empty?)
        end
      else
        @posts = base_posts.page(params[:page])
      end
    end
  end

  private

  def search_and_sort_issues(keyword, current_search_group, limit)
    current_user = User.find(19)
    tags = (keyword.try(:split) || []).map(&:strip).reject(&:blank?)
    result = Issue.searchable_issues.searchable_issues(current_user).alive
    result = result.of_group(current_search_group) if current_search_group.present?
    if keyword.present?
      issues_by_landing_page_subject = LandingPage.parsed_section_for_all_issue_subject(tags)
      result = result.where(id:
        Issue.search_for(smart_search_keyword(keyword)).union(Issue.tagged_with(tags, any: true)).union(issues_by_landing_page_subject).except(:select).select(:id)
      )
    end
    result = result.hottest
    result = result.limit(limit)
    result
  end

  def search_and_sort_groups(keyword, current_search_group)
    return Group.none if current_search_group.present?
    return Group.none if keyword.blank?

    result = Group.searchable_groups(current_user).search_for(smart_search_keyword(keyword))
    result = result.hottest
    result
  end
end
