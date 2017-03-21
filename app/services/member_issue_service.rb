class MemberIssueService

  attr_accessor :issue
  attr_accessor :current_user

  def initialize(issue:, current_user:, is_auto: false)
    @issue = issue
    @current_user = current_user
    @is_auto = is_auto
  end

  def call
    return if @issue.private_blocked?(@current_user)
    @member = @issue.members.build(user: @current_user)
    @member.user = @current_user
    ActiveRecord::Base.transaction do
      if @member.save
        @issue.member_requests.where(user: @member.user).try(:destroy_all)
        @issue.invitations.where(recipient: @member.user).try(:destroy_all)
      end
    end
    if @member.persisted?
      MessageService.new(@member).call
      MemberMailer.deliver_all_later_on_create(@member) unless @is_auto
    end

    return @member
  end
end
