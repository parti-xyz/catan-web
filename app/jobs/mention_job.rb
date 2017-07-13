class MentionJob
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(mentionable_type, mentionable_id)
    mentionable_model = mentionable_type.safe_constantize
    return if mentionable_model.blank?
    mentionable = mentionable_model.find_by(id: mentionable_id)
    return if mentionable.blank?

    mentionable.perform_mentions_now
  end
end
