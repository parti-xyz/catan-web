class VotePostService

  attr_accessor :specific
  attr_accessor :current_user

  def initialize(specific:, current_user:)
    @specific = specific
    @current_user = current_user
  end

  def agree
    previous_vote = self.specific.vote_by current_user
    if previous_vote.present?
      vote = previous_vote
    else
      vote = specific.votes.build
      vote.user = current_user
    end
    vote.choice = 'agree'
    vote.save
    vote
  end

  def disagree
    previous_vote = self.specific.vote_by current_user
    if previous_vote.present?
      vote = previous_vote
    else
      vote = specific.votes.build
      vote.user = current_user
    end
    vote.choice = 'disagree'
    vote.save
    vote
  end

  def unsure
    previous_vote = self.specific.vote_by current_user
    if previous_vote.present?
      vote = previous_vote
    else
      vote = specific.votes.build
      vote.user = current_user
    end
    vote.choice = 'unsure'
    vote.save
    vote
  end
end
