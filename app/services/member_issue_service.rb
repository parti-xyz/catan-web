class MemberIssueService

  attr_accessor :issue
  attr_accessor :current_user

  def initialize(issue:, current_user:)
    @issue = issue
    @current_user = current_user
  end

  def call
    member = @issue.members.build(user: @current_user)
    member.save
    member
  end
end
