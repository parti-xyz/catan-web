class FcmJob < ApplicationJob
  include Sidekiq::Worker

  def perform(id)
    message = Message.find_by(id: id)

    Rails.logger.debug("FCM JOB : #{id}")
    if message.try(:fcm_pushable?) and
        (message.user.current_device_tokens.any? or ENV['FCM_FAKE'])
      current_message = fcm_message(message.user, message)

      if ENV['FCM_FAKE']
        Rails.logger.debug("FCM MESSAGE : #{current_message}")
        return
      end

      return unless Rails.env.production?

      registration_ids = message.user.current_device_tokens.pluck(:registration_id)
      registration_ids.each_slice(1000) do |ids|
        Rails.logger.debug(ids.inspect)
        response = fcm.send(ids, current_message)
        if message.user.enable_trace_device_token?
          Rails.logger.info("FCM TRACE\n * message.user.nickname : #{message.user.nickname}\n * response : #{response}")
        else
          Rails.logger.debug(response)
        end
        results = JSON.parse(response[:body])["results"]
        results.map{ |t| t["error"] }.each_with_index do |value, i|
          if "NotRegistered" == value
            token = message.user.current_device_tokens.find_by registration_id: registration_ids[i]
            token.destroy
          end
        end
        results.map{ |t| t["registration_id"] }.each_with_index do |value, i|
          if value.present?
            token = message.user.device_tokens.find_by registration_id: registration_ids[i]
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
    result['notification'] = { 'title' => result['data']['title'], 'body' => result['data']['body'] }
    result['notification'].merge!('sound' => 'default') if user.push_notification_mode == :on
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
