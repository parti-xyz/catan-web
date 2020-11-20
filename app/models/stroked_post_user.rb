class StrokedPostUser < ApplicationRecord
  LIMIT = 5
  belongs_to :user
  belongs_to :post

  scope :recent, -> { order(created_at: :desc) }
end