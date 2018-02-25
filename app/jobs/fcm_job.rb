class FcmJob
  include Sidekiq::Worker

  def perform(id)
    return unless Rails.env.production?
    message = Message.find_by(id: id)
    if message.present? and
        message.user.enable_push_notification? and
        message.user.current_device_tokens.any?
      current_message = fcm_message(message.user, message)
      registration_ids = message.user.current_device_tokens.pluck(:registration_id)
      registration_ids.each_slice(1000) do |ids|
        Rails.logger.debug(ids.inspect)
        response = fcm.send(ids, current_message)
        Rails.logger.debug(response)
        results = JSON.parse(response[:body])["results"]
        results.map{ |t| t["error"] }.each_with_index do |value, i|
          if "NotRegistered" == value
            token = message.user.current_device_tokens.find_by registration_id: registration_ids[i]
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

  def fcm_message(user, message)
    parsed_asset_url = URI.parse(Rails.application.config.asset_host || "https://parti.xyz")
    host = parsed_asset_url.host
    is_https = (parsed_asset_url.scheme == 'https')
    json = ApplicationController.renderer.new(
      http_host: host,
      https: is_https)
    .render(
      partial: "messages/fcm/#{message.messagable.class.model_name.singular}",
      locals: { message: message }
    )

    result = JSON.parse(json)
    result['time_to_live'] = 24.hours.to_i
    result['data'].merge!({ 'user_id' => user.id })
    result['notification'] = { 'title' => result['data']['title'], 'body' => result['data']['body'], 'sound' => 'default' }
    result
  end

  def self.test(user, id = nil)
    job = FcmJob.new
    fcm = job.fcm
    last_message = user.messages.last
    ids = (id.nil? ? DeviceToken.where(user_id: user.id).map(&:registration_id) : [id])
    fcm.send(ids, job.fcm_message(user, last_message))
  end
end
