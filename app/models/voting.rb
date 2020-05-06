class Voting < ApplicationRecord
  extend Enumerize
  include Choosable

  belongs_to :user
  belongs_to :poll, counter_cache: true
  counter_culture :poll, column_name: proc {|model| Voting.sure?(model.choice) ? "#{model.choice}_votings_count" : nil },
    column_names: {
      Voting.agree => :agree_votings_count,
      Voting.disagree => :disagree_votings_count,
      Voting.neutral => :neutral_votings_count,
    }
  counter_culture :poll, column_name: proc {|model| Voting.sure?(model.choice) ? 'sure_votings_count' : nil },
    column_names: {
      Voting.sure => :sure_votings_count
    }

  validates :user, uniqueness: {scope: [:poll]}
  validates :poll, presence: true
  validates :choice, presence: true

  scope :recent, -> { order(id: :desc) }
  scope :latest, -> { after(1.day.ago) }
  scope :by_issue, ->(issue) { joins(:poll).where(polls: {issue_id: issue})}
  scope :previous_of_voting, ->(voting) { where('votings.updated_at < ?', voting.updated_at) if voting.present? }
end
