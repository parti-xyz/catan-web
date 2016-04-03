class Search < ActiveRecord::Base
  belongs_to :searchable, polymorphic: true

  scoped_search on: [:content]
end
