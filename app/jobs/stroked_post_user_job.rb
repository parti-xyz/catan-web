class StrokedPostUserJob < ApplicationJob
  include Sidekiq::Worker
  sidekiq_options unique: :while_executing

  def perform(post_id, user_id = nil)
    post = Post.find_by(id: post_id)
    return if post.blank?

    new_user_ids = [post.user_id, user_id]
    new_user_ids << post.comments.select(:user_id).distinct.pluck(:user_id).to_a

    if post.wiki.present?
      new_user_ids << post.wiki.wiki_authors.pluck(:user_id).to_a
    end

    if post.poll.present?
      new_user_ids << User.where(id: post.poll.votings.select(:user_id).distinct).pluck(:id).to_a
    end

    if post.survey.present?
      new_user_ids << User.where(id: post.survey.feedbacks.select(:user_id).distinct).pluck(:id).to_a
    end

    new_user_ids = new_user_ids.flatten.compact.uniq
    old_user_ids = post.stroked_post_users.pluck(:user_id).to_a.uniq

    post.stroked_post_users.where(user_id: (old_user_ids - new_user_ids)).delete_all
    (new_user_ids - old_user_ids).each do |new_user_id|
      stroked_post_user = post.stroked_post_users.create(user_id: new_user_id)
      Rails.logger.debug stroked_post_user.inspect
    end

    post.reload
    post.stroked_post_users.where.not(id: post.stroked_post_users.recent.limit(StrokedPostUser::LIMIT).to_a).delete_all
    post.save
  end
end
