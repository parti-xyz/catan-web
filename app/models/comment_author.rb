class CommentAuthor < ApplicationRecord
  belongs_to :user
  belongs_to :comment

  scope :recent, -> { order(created_at: :desc) }
end