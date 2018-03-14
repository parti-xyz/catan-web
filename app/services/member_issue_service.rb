class MemberIssueService

  attr_accessor :issue
  attr_accessor :user

  def initialize(issue:, user:, is_organizer: false, admit_message: nil,
    created_at: nil, updated_at: nil,
    need_to_message_organizer: true, is_force: false)
    @issue = issue
    @user = user
    @is_organizer = is_organizer
    @created_at = created_at
    @updated_at = updated_at
    @admit_message = admit_message
    @need_to_message_organizer = need_to_message_organizer
    @is_force = is_force
  end

  def call
    return if !@is_force and @issue.private_blocked?(@user)
    return @issue.members.find_by(user_id: @user) if @issue.member?(@user)

    @member = @issue.members.build(user: @user, is_organizer: @is_organizer, admit_message: @admit_message)
    @member.created_at = @created_at if @created_at.present?
    @member.updated_at = @updated_at if @updated_at.present?
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
    if @member.persisted? and @need_to_message_organizer
      MessageService.new(@member).call
      MemberMailer.deliver_all_later_on_create(@member)
    end
    return @member
  end
end
