class IssueCreateNotificationJob
  include Sidekiq::Worker
  sidekiq_options unique: :while_executing

  def perform(issue_id, user_id)
    # issue = Issue.find_by(id: issue_id)
    # return if issue.blank?
    # return if issue.group.indie?
    # return if issue.private?

    # creating_user = User.find_by(id: user_id)
    # return if creating_user.blank?

    # MessageService.new(issue, sender: creating_user, action: :create).call

    # issue.group.member_users.each do |user|
    #   PartiMailer.on_create(creating_user.id, user.id, issue.id).deliver_later
    # end
  end
end
