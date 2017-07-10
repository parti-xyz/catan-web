class WikiCaptureJob
  include Sidekiq::Worker

  def perform(id)
    wiki = Wiki.find_by(id: id)
    return if wiki.blank?

    wiki.capture!
  end
end
