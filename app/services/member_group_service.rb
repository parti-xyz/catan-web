class MemberGroupService

  attr_accessor :group
  attr_accessor :user

  def initialize(group:, user:)
    @group = group
    @user = user
  end

  def call
    return if @group.blank? or @group.member? self
    ActiveRecord::Base.transaction do
      @member = @group.members.create(user: @user)
      return if @member.blank?
      (group.default_issues || []).each do |issue|
        MemberIssueService.new(issue: issue, user: @user, is_auto: true).call
      end
      member_requests = @group.member_requests.where(user_id: @user.id)
      if member_requests.any?
        member_requests.destroy_all
      end
      invitations = @group.invitations.where(recipient_id: @user.id)
      if invitations.any?
        invitations.destroy_all
      end
      email_invitations = @group.invitations.where(recipient_email: @user.email)
      if email_invitations.any?
        email_invitations.destroy_all
      end
    end
    return @member
  end
end
