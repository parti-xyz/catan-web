class WikiCaptureJob < ApplicationJob
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(id)
    # wiki = Wiki.find_by(id: id)
    # return if wiki.blank?

    # wiki.capture!
  end
end
