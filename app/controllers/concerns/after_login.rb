module AfterLogin
  extend ActiveSupport::Concern

  def after_omniauth_login
    return unless user_signed_in?
    omniauth_params = request.env['omniauth.params'] || session["omniauth.params_data"] || {}

    return if omniauth_params['after_login'].blank?
    after_login = JSON.parse(omniauth_params['after_login'])
    case after_login['action']
    when 'opinion_vote_agree'
      specific = Opinion.find after_login['id']
      VotePost.new(specific: specific, current_user: current_user).agree
    when 'opinion_vote_disagree'
      specific = Opinion.find after_login['id']
      VotePost.new(specific: specific, current_user: current_user).disagree
    when 'issue_watch'
      issue = Issue.find after_login['id']
      WatchIssue.new(issue: issue, current_user: current_user).call
    end

    session["omniauth.params_data"] = nil
  end
end
