module Searchable
  extend ActiveSupport::Concern

  included do
    after_save :update_searchable_content
    has_one :search, as: :searchable, dependent: :destroy
  end

  def searchable?
    true
  end

  def search_indexing
    search = Search.find_or_initialize_by(searchable: self)
    if self.searchable?
      search.content = self.searchable_content
      search.created_at = self.created_at
      search.save
    else
      search.destroy
    end
  end

  private

  def update_searchable_content
    search_indexing
  end
end
