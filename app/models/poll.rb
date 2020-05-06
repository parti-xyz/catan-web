class Poll < ApplicationRecord
  include Expirable

  has_one :post, dependent: :destroy
  has_many :votings, dependent: :destroy
  has_one :current_user_voting,
    -> { where(user_id: Current.user.try(:id)) },
    class_name: "Voting"

  scope :recent, -> { order(updated_at: :desc) }
  scope :latest, -> { after(1.day.ago) }
  scope :previous_of_poll, ->(poll) { where('polls.updated_at < ?', poll.updated_at) if poll.present? }

  validates :title, presence: true

  def voting_by voter
    if voter == Current.user
      self.current_user_voting
    else
      self.votings.find_by(user: voter)
    end
  end

  def voting_by? voter
    votings_exists_by_user? voter
  end

  def agree_by? voter
    votings_exists_by_user? voter, 'agree'
  end

  def disagree_by? voter
    votings_exists_by_user? voter, 'disagree'
  end

  def neutral_by? voter
    votings_exists_by_user? voter, 'neutral'
  end

  def sured_by? voter, choice = 'sure'
    votings_exists_by_user? voter, choice
  end

  def unsured_by? voter
    votings_exists_by_user? voter, 'unsure'
  end

  def sure_any_votings?
    self.sure_votings_count > 0
  end

  private

  def votings_exists_by_user? voter, choice = nil
    return false if voter.blank?
    voting = voting_by(voter)
    return false if voting.blank?
    if choice.blank?
      voting.choice.present?
    elsif choice == 'sure'
      voting.sure?
    else
      voting.choice == choice
    end
  end
end
