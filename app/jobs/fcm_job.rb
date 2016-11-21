class FcmJob
  include Sidekiq::Worker

  def perform(id)
    message = Message.find_by(id: id)
    if message.present? and message.user.device_tokens.any?
      Rails.logger.debug(fcm_message(message).inspect)
      registration_ids = message.user.device_tokens.pluck(:registration_id)
      registration_ids.each_slice(1000) do |ids|
        Rails.logger.debug(ids.inspect)
        response = fcm.send(ids, fcm_message(message))
        Rails.logger.debug(response)
        results = JSON.parse(response[:body])["results"]
        results.map{ |t| t["error"] }.each_with_index do |value, i|
          if "NotRegistered" == value
            token = message.user.device_tokens.find_by registration_id: registration_ids[i]
            token.destroy
          end
        end
        results.map{ |t| t["registration_id"] }.each_with_index do |value, i|
          if value.present?
            token = user.device_tokens.find_by registration_id: registration_ids[i]
            token.update_attributes(registration_id: value)
          end
        end
      end
    end
  end

  def fcm
    @fcm ||= FCM.new(ENV['FCM_KEY'], {priority: 'high'})
  end

  def fcm_message(message)
    json = ApplicationController.renderer.render(
      partial: "messages/fcm/#{message.messagable.class.model_name.singular}",
      locals: { message: message }
    )

    result = JSON.parse(json)
    result['notification'].merge!({ 'sound' => 'default', 'click_action' => 'FCM_PLUGIN_ACTIVITY' })
    result
  end
end
