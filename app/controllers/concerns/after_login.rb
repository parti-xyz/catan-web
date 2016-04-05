module AfterLogin
  extend ActiveSupport::Concern

  def after_omniauth_login
    return unless user_signed_in?
    omniauth_params = request.env['omniauth.params'] || session["omniauth.params_data"] || {}

    return if omniauth_params['after_login'].blank?
    after_login = JSON.parse(omniauth_params['after_login'])
    case after_login['action']
    when 'opinion_vote_agree'
      specific = Opinion.find_by id: after_login['id']
      VotePostService.new(specific: specific, current_user: current_user).agree if specific.present?
    when 'opinion_vote_disagree'
      specific = Opinion.find_by id: after_login['id']
      VotePostService.new(specific: specific, current_user: current_user).disagree if specific.present?
    when 'issue_watch'
      issue = Issue.find_by id: after_login['id']
      WatchIssueService.new(issue: issue, current_user: current_user).call if issue.present?
    when 'comment_upvote'
      comment = Comment.find_by id: after_login['id']
      UpvoteCommentService.new(comment: comment, current_user: current_user).call if comment.present?
    end

    session["omniauth.params_data"] = nil
  end
end
