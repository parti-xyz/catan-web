class Group::ManagementsController < GroupBaseController
  before_action :only_organizer, only: [:index]

  def index
    organizer_group = Group.find_by(slug: 'organizer')
    @posts_pinned = organizer_group.pinned_posts(current_user)

    group_issues = Issue.where(group_slug: current_group.slug)
    group_posts = Post.where(issue: group_issues)

    #total
    @data = [["게시글", group_posts.group_by_month('posts.created_at').count],
             ["공감",Upvote.where(issue: group_issues).group_by_month('upvotes.created_at').count],
             ["댓글", Comment.where(post: group_posts).group_by_month('comments.created_at').count]]

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

  def statistics
  end

end
