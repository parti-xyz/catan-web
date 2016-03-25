class Upvote < ActiveRecord::Base
  belongs_to :user
  belongs_to :comment, counter_cache: true

  validates :user, presence: true
  validates :comment, presence: true
  validates :user, uniqueness: {scope: [:comment]}

  scope :recent, -> { order(created_at: :desc) }
end
