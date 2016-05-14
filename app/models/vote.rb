class Vote < ActiveRecord::Base
  extend Enumerize
  include Choosable

  belongs_to :user
  belongs_to :post, counter_cache: true

  validates :user, uniqueness: {scope: [:post]}
  validates :post, presence: true
  validates :choice, presence: true

  scope :recent, -> { order(updated_at: :desc) }
  scope :latest, -> { after(1.day.ago) }
  scope :by_issue, ->(issue) { joins(:post).where(posts: {issue_id: issue})}
  scope :previous_of_vote, ->(vote) { where('votes.created_at < ?', vote.updated_at) if vote.present? }
end
