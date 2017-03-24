class SurveyClosedMessagesJob
  include Sidekiq::Worker

  def perform
    Survey.need_to_reset_sent_closed_message_at.update_all(sent_closed_message_at: nil)
    Survey.need_to_send_closed_message.each do |survey|
      MessageService.new(survey, action: :closed).call
      SurveyMailer.deliver_all_later_on_closed(survey)
      survey.touch(:sent_closed_message_at)
    end
  end
end
