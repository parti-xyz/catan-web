class Admin::LandingPagesController < AdminController
  def index
    @posts = Post.of_public_issues_of_public_group
                 .where('posts.created_at > ? and posts.file_sources_count > 0', (Date.today - 15))
  end
end
