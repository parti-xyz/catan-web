class SiteNoticeJob < ApplicationJob
  include Sidekiq::Worker

  def perform(title, body, test_user_id = nil)
    client = Postmark::ApiClient.new(ENV['POSTMARKER_API_KEY'])

    if test_user_id.present?
      test_user = User.find_by id: test_user_id
      return if test_user.blank?

      messages = []
      messages << SiteNoticeMailer.basic(test_user, title, body)
      client.deliver_messages(messages)
    else
      if !Rails.env.production?
        client = Postmark::ApiClient.new('POSTMARK_API_TEST')
      end

      User.find_in_batches(batch_size: 500) do |users|

        messages = []
        users.each do |user|
          messages << SiteNoticeMailer.basic(user, title, body)
        end
        client.deliver_messages(messages)
      end
    end
  end
end
