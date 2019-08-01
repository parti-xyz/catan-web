class WikiCaptureJob < ApplicationJob
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(id)
    return if Rails.env.development? or Rails.env.test?

    wiki = Wiki.find_by(id: id)
    return if wiki.blank?

    wiki.capture!
  end
end
