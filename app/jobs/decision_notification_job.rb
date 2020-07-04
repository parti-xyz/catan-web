class DecisionNotificationJob < ApplicationJob
  include Sidekiq::Worker
  sidekiq_options unique: :while_executing

  def perform(decision_user_id, decision_history_id)
    decision_user = User.find_by(id: decision_user_id)
    decision_history = DecisionHistory.find_by(id: decision_history_id)
    return if decision_user.blank? or decision_history.blank?

    histories_chunk = []
    current_history = decision_history
    while(1) do
      previous_history = current_history.previous_of_current_post
      break if previous_history.nil?
      break if previous_history.user != current_history.user
      break if (current_history.created_at.to_i - previous_history.created_at.to_i) > 5 * 60
      histories_chunk << previous_history
      current_history = previous_history
    end

    not_sent_histories = histories_chunk.select { |decision_history| decision_history.mailed_at.blank? }
    if histories_chunk.blank? or not_sent_histories.any?
      post = Post.find_by(id: decision_history.post_id)
      MessageService.new(decision_history.post, sender: decision_user, action: :decision).call(decision_body: decision_history.body)
    end

    decision_history.update_columns(mailed_at: DateTime.now)
    not_sent_histories.each do |decision_history|
      decision_history.update_columns(mailed_at: DateTime.now)
    end
  end
end
