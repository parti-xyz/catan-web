module AfterLogin
  extend ActiveSupport::Concern

  def after_omniauth_login
    return unless user_signed_in?
    omniauth_params = request.env['omniauth.params'] || session["omniauth.params_data"] || {}

    return if omniauth_params['after_login'].blank?
    after_login = JSON.parse(omniauth_params['after_login'])
    case after_login['action']
    when 'poll_vote_agree'
      poll = Poll.find_by id: after_login['id']
      VotingPollService.new(poll: poll, current_user: current_user).agree if poll.present?
    when 'poll_vote_disagree'
      poll = Poll.find_by id: after_login['id']
      VotingPollService.new(poll: poll, current_user: current_user).disagree if poll.present?
    when 'poll_vote_unsure'
      poll = Poll.find_by id: after_login['id']
      VotingPollService.new(poll: poll, current_user: current_user).unsure if poll.present?
    when 'issue_member'
      issue = Issue.find_by id: after_login['id']
      MemberIssueService.new(issue: issue, current_user: current_user).call if issue.present?
    end

    session["omniauth.params_data"] = nil
  end
end
