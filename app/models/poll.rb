class Poll < ActiveRecord::Base
  include Grape::Entity::DSL
  entity do
    expose :id, :title, :votings_count
    expose :latest_agreed_voting_users, using: User::Entity do |instance|
      instance.votings.recent.limit(5).agreed.map &:user
    end
    expose :latest_disagreed_voting_users, using: User::Entity do |instance|
      instance.votings.recent.limit(5).disagreed.map &:user
    end
    expose :agreed_votings_count do |instance|
      instance.votings.agreed.count
    end
    expose :disagreed_votings_count do |instance|
      instance.votings.disagreed.count
    end
    with_options(if: lambda { |instance, options| options[:current_user].present? }) do
      expose :my_choice do |instance, options|
        instance.voting_by(options[:current_user]).try(:choice)
      end
    end
  end

  has_one :post, dependent: :destroy
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

  def sured_by? voter
    votings.exists? user: voter, choice: ['agree', 'disagree']
  end

  def unsured_by? voter
    votings.exists? user: voter, choice: 'unsure'
  end
end
