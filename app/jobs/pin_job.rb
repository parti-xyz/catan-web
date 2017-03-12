class PinJob
  include Sidekiq::Worker

  def perform(post_id, user_id)
    post = Post.find_by(id: post_id)
    return if post.blank?
    user = User.find_by(id: user_id)

    post.notifiy_pinned_now(user)
  end
end
