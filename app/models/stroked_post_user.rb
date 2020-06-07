class StrokedPostUser < ApplicationRecord
  belongs_to :user
  belongs_to :post

  scope :recent, -> { order(created_at: :desc) }
end