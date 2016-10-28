class Poll < ActiveRecord::Base
  belongs_to :talk
  has_many :votings, dependent: :destroy do
    def users
      self.map(&:user).uniq
    end

    def partial_included_with(someone)
      partial = recent.limit(100)
      if !partial.map(&:user).include?(someone)
        (partial.all << find_by(user: someone)).compact
      else
        partial.all
      end
    end

    def point
      agreed.count - disagreed.count
    end
  end

  validates :title, presence: true

  def voting_by voter
    votings.where(user: voter).first
  end

  def votinged_by? voter
    votings.exists? user: voter
  end

  def agreed_by? voter
    votings.exists? user: voter, choice: 'agree'
  end

  def disagreed_by? voter
    votings.exists? user: voter, choice: 'disagree'
  end

  def sured_by? voter
    votings.exists? user: voter, choice: ['agree', 'disagree']
  end

  def unsured_by? voter
    votings.exists? user: voter, choice: 'unsure'
  end
end
