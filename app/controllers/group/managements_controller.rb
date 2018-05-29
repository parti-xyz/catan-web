class Group::ManagementsController < Group::BaseController
  before_action :only_organizer, only: [:index]

  def index
    organizer_group = Group.find_by(slug: 'organizer')
    @posts_pinned = organizer_group.pinned_posts(current_user)

    group_issues = Issue.where(group_slug: current_group.slug)
    group_posts = Post.where(issue: group_issues)

    #total
    oldest_post = group_posts.oldest
    newest_post = group_posts.newest

    delta = newest_post.created_at - oldest_post.created_at
    @data = if delta > 6.weeks
      [["게시글", group_posts.group_by_month('posts.created_at', format: "%Y/%m").count],
       ["공감",Upvote.where(issue: group_issues).group_by_month('upvotes.created_at', format: "%Y/%m").count],
       ["댓글", Comment.where(post: group_posts).group_by_month('comments.created_at', format: "%Y/%m").count]]
    else
      [["게시글", group_posts.group_by_day('posts.created_at', format: "%Y/%m/%d").count],
       ["공감",Upvote.where(issue: group_issues).group_by_day('upvotes.created_at', format: "%Y/%m/%d").count],
       ["댓글", Comment.where(post: group_posts).group_by_day('comments.created_at', format: "%Y/%m/%d").count]]
    end


    @hottest_posts = group_posts.hottest.limit(5)
    @active_users_by_posts = group_posts.group('posts.user_id')
                            .order('count_id desc')
                            .count('id').first(10)

    @active_users_by_comments = Comment.where(post: group_posts)
                                .group('comments.user_id')
                                .order('count_id desc')
                                .count('id').first(10)

    @active_users_by_upvotes = Upvote.where(issue: group_issues)
                          .group('upvotes.user_id')
                          .order('count_id desc')
                          .count('id').first(10)

  end

  def suggest
    ToAdminMailer.suggest(params[:suggest], current_user.id).deliver_later
    flash[:success] = "요청을 성공적으로 보냈습니다"
    redirect_to group_managements_path
  end

end
