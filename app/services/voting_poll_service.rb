class VotingPollService

  attr_accessor :specific
  attr_accessor :current_user

  def initialize(specific:, current_user:)
    @specific = specific
    @current_user = current_user
  end

  def agree
    previous_voting = self.specific.voting_by current_user
    if previous_voting.present?
      voting = previous_voting
    else
      voting = specific.votings.build
      voting.user = current_user
    end
    voting.choice = 'agree'
    voting.save
    voting
  end

  def disagree
    previous_voting = self.specific.voting_by current_user
    if previous_voting.present?
      voting = previous_voting
    else
      voting = specific.votings.build
      voting.user = current_user
    end
    voting.choice = 'disagree'
    voting.save
    voting
  end

  def unsure
    previous_voting = self.specific.voting_by current_user
    if previous_voting.present?
      voting = previous_voting
    else
      voting = specific.votings.build
      voting.user = current_user
    end
    voting.choice = 'unsure'
    voting.save
    voting
  end
end
