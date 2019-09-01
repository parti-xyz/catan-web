class IssueCreateService
  def initialize(issue:, current_user:, current_group:, flash:)
    @issue = issue
    @current_user = current_user
    @current_group = current_group
    @flash = flash
  end

  def call
    if @current_group.try(:will_violate_issues_quota?, @issue)
      @flash[:notice] = t('labels.group.met_issues_quota')
      return false
    end

    @issue.strok_by(@current_user)
    @issue.read_if_no_unread_posts!(@current_user)

    if @issue.save
      MemberIssueService.new(issue: @issue, user: @current_user, is_organizer: true, need_to_message_organizer: false, is_force: true).call
      if @issue.is_default?
        IssueForceDefaultJob.perform_async(@issue.id, @current_user.id)
      end
      IssueCreateNotificationJob.perform_async(@issue.id, @current_user.id)
      return true
    else
      return false
    end
  end
end
