class MemberIssueService

  attr_accessor :issue
  attr_accessor :user

  def initialize(issue:, user:, is_auto: false)
    @issue = issue
    @user = user
    @is_auto = is_auto
  end

  def call
    return if @issue.private_blocked?(@user)
    @member = @issue.members.build(user: @user)
    @member.user = @user
    ActiveRecord::Base.transaction do
      if @member.save
        @issue.member_requests.where(user: @member.user).try(:destroy_all)
        @user.update_attributes(member_issues_changed_at: DateTime.now)
      end
    end
    if @member.persisted?
      MessageService.new(@member).call
      MemberMailer.deliver_all_later_on_create(@member) unless @is_auto
    end

    return @member
  end
end
