class Voting < ActiveRecord::Base
  extend Enumerize
  include Choosable

  belongs_to :user
  belongs_to :poll, counter_cache: true

  validates :user, uniqueness: {scope: [:poll]}
  validates :poll, presence: true
  validates :choice, presence: true

  scope :recent, -> { order(updated_at: :desc) }
  scope :latest, -> { after(1.day.ago) }
  scope :by_issue, ->(issue) { joins(:poll).where(polls: {issue_id: issue})}
  scope :previous_of_voting, ->(voting) { where('votings.updated_at < ?', voting.updated_at) if voting.present? }
end
