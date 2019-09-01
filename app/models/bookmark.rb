class Bookmark < ApplicationRecord
  acts_as_taggable

  belongs_to :user
  belongs_to :post
end
