class WatchIssueService

  attr_accessor :issue
  attr_accessor :current_user

  def initialize(issue:, current_user:)
    @issue = issue
    @current_user = current_user
  end

  def call
    watch = @issue.watches.build(user: @current_user)
    watch.save
    watch
  end
end
