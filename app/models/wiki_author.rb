class WikiAuthor < ApplicationRecord
  belongs_to :user
  belongs_to :wiki

  scope :recent, -> { order(created_at: :desc) }
end