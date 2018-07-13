class Poll < ActiveRecord::Base
  include Expirable

  has_one :post, dependent: :destroy
  has_many :votings, dependent: :destroy do
    def partial_included_with(someone)
      partial = recent.limit(100)
      partial.all << find_by(user: someone)
      partial.compact.uniq
    end

    def point
      agreed.count - disagreed.count
    end
  end

  scope :recent, -> { order(updated_at: :desc) }
  scope :latest, -> { after(1.day.ago) }
  scope :previous_of_poll, ->(poll) { where('polls.updated_at < ?', poll.updated_at) if poll.present? }

  validates :title, presence: true

  def voting_by voter
    votings.where(user: voter).first
  end

  def voting_by? voter
    votings.exists? user: voter
  end

  def agreed_by? voter
    votings.exists? user: voter, choice: 'agree'
  end

  def disagreed_by? voter
    votings.exists? user: voter, choice: 'disagree'
  end

  def neutral_by? voter
    votings.exists? user: voter, choice: 'neutral'
  end

  def sured_by? voter
    votings.exists? user: voter, choice: ['agree', 'disagree', 'neutral']
  end

  def unsured_by? voter
    votings.exists? user: voter, choice: 'unsure'
  end
end
