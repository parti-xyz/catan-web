class SearchIndexingService
  def initialize(searchable)
    @searchable = searchable
  end

  def call
    search_indexing
  end
end
