class VotingPollService

  attr_accessor :poll
  attr_accessor :current_user

  def initialize(poll:, current_user:)
    @poll = poll
    @current_user = current_user
  end

  def agree
    unless self.poll.open?
      return
    end

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
    unless self.poll.open?
      return
    end

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

  def neutral
    unless self.poll.open?
      return
    end

    previous_voting = self.poll.voting_by current_user
    if previous_voting.present?
      voting = previous_voting
    else
      voting = poll.votings.build
      voting.user = current_user
    end
    voting.choice = 'neutral'
    if voting.save
      strok_post
    end
    voting
  end

  def unsure
    unless self.poll.open?
      return
    end

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
    return if self.poll.try(:post).blank?
    self.poll.post.issue.deprecated_read_if_no_unread_posts!(current_user)
  end
end
