class VotingPollService

  attr_accessor :poll
  attr_accessor :current_user

  def initialize(poll:, current_user:)
    @poll = poll
    @current_user = current_user
  end

  def agree
    previous_voting = self.poll.voting_by current_user
    if previous_voting.present?
      voting = previous_voting
    else
      voting = poll.votings.build
      voting.user = current_user
    end
    voting.choice = 'agree'
    if voting.save
      strok_post
    end
    voting
  end

  def disagree
    previous_voting = self.poll.voting_by current_user
    if previous_voting.present?
      voting = previous_voting
    else
      voting = poll.votings.build
      voting.user = current_user
    end
    voting.choice = 'disagree'
    if voting.save
      strok_post
    end
    voting
  end

  def unsure
    previous_voting = self.poll.voting_by current_user
    if previous_voting.present?
      voting = previous_voting
    else
      voting = poll.votings.build
      voting.user = current_user
    end
    voting.choice = 'unsure'
    if voting.save
      strok_post
    end
    voting
  end

  private

  def strok_post
    self.poll.try(:post).try(:generous_strok_by!, current_user, :voting)
  end
end
