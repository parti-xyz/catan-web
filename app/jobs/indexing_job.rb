class IndexingJob
  include Sidekiq::Worker
  sidekiq_options unique: :while_executing

  def perform
    [LinkSource, Opinion, Talk].each do |m|
      m.find_each do |searchable|
        searchable.search_indexing
      end
    end
  end
end
