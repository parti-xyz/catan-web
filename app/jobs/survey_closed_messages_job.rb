class SurveyClosedMessagesJob < ApplicationJob
  include Sidekiq::Worker

  def perform
    Survey.need_to_reset_sent_closed_message_at.update_all(sent_closed_message_at: nil)
    Survey.need_to_send_closed_message.each do |survey|
      unless survey.post.blank?
        SendMessage.run(source: survey, sender: survey.post_for_message.user, action: :closed_survey)
      end
      survey.touch(:sent_closed_message_at)
    end
  end
end
