class MemberIssueService

  attr_accessor :issue
  attr_accessor :user

  def initialize(issue:, user:, is_auto: false, is_force_default: false, organizer_user: nil)
    @issue = issue
    @user = user
    @is_auto = is_auto
    @is_force_default = is_force_default
    @organizer_user = organizer_user
  end

  def call
    return if @issue.private_blocked?(@user)
    return if @issue.member?(@user)

    @member = @issue.members.build(user: @user)
    @member.user = @user
    ActiveRecord::Base.transaction do
      if @member.save
        @issue.member_requests.where(user: @member.user).try(:destroy_all)
        @user.update_attributes(member_issues_changed_at: DateTime.now)
      end

      if !@issue.group.indie? and !@issue.group.member?(@user)
        MemberGroupService.new(group: @issue.group, user: @user).call
      end
    end
    if @member.persisted? and !@is_auto
      MessageService.new(@member).call
      MemberMailer.deliver_all_later_on_create(@member)
    end
    if @member.persisted? and @is_force_default
      MessageService.new(@member, sender: @organizer_user, action: :force_default).call
      MemberMailer.deliver_all_later_on_force_default(@member, @organizer_user)
    end

    return @member
  end
end
