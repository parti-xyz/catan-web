class CrawlingJob
  include Sidekiq::Worker
  sidekiq_options unique: :while_executing

  def perform(id)
    source = LinkSource.find_by(id: id)
    return unless source.present?

    10.times do
      break if crawl!(source)
      sleep(1.0/2.0)
    end
  end

  def crawl!(source)
    data = fetch_data(source)
    return false unless valid_open_graph?(data)

    ActiveRecord::Base.transaction do
      if source.url != data.url
        origin = LinkSource.where(url: data.url).oldest
        if origin.blank? or origin == source
          source.url = data.url
          source.set_crawling_data(data)
          source.save!
          source.articles.each do |article|
            article.link = data.url
            article = Article.merge_by_link!(article)
            article.save!
          end
        else
          origin.set_crawling_data(data)
          origin.save!
          source.articles.each do |article|
            article.link = data.url
            article = Article.merge_by_link!(article)
            article.save!
          end
          source.destroy!
        end
      else
        source.set_crawling_data(data)
        source.save!
      end
    end
  end

  def fetch_data(source)
    OpenGraph.new(source.url)
  end

  def valid_open_graph?(data)
    data.present? and data.title.present? and data.title != data.src
  end
end
