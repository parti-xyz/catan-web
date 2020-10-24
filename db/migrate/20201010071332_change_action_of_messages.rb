class ChangeActionOfMessages < ActiveRecord::Migration[5.2]
  def change
    Message.where(action: nil).where(messagable_type: 'Comment').update_all(action: 'create_comment')
    Message.where(action: 'create').where(messagable_type: 'Comment').update_all(action: 'create_comment')

    Message.where(action: nil).where(messagable_type: 'Post').update_all(action: 'create_post')
    Message.where(action: 'create').where(messagable_type: 'Post').update_all(action: 'create_post')
    Message.where(action: 'pinned').where(messagable_type: 'Post').update_all(action: 'pin_post')
    Message.where(action: 'decision').where(messagable_type: 'Post').delete_all

    Message.where.not(action: [:mention, :pin_post]).where(messagable_type: 'Post').joins('JOIN mentions on mentions.mentionable_id = messages.messagable_id and mentions.mentionable_type = messages.messagable_type and mentions.user_id = messages.user_id').update_all(action: 'mention')


    Message.where(messagable_type: 'Issue').where(action: 'create').update_all(action: 'create_issue')

    Message.where(action: nil).where(messagable_type: 'Upvote').update_all(action: 'upvote')
    Message.where(messagable_type: 'Option').delete_all
    Message.where(messagable_type: 'Survey').where(action: 'closed').update_all(action: 'closed_survey')


    Message.where(messagable_type: 'Member').where(action: 'new_organizer').joins('join members on members.id = messages.messagable_id').where("members.joinable_type = 'Group'").update_all(action: 'assign_group_organizer')
    Message.where(messagable_type: 'Member').where(action: 'new_organizer').joins('join members on members.id = messages.messagable_id').where("members.joinable_type = 'Issue'").update_all(action: 'assign_issue_organizer')

    Message.where(messagable_type: 'Member').where(action: 'ban').joins('join members on members.id = messages.messagable_id').where("members.joinable_type = 'Group'").update_all(action: 'ban_group_organizer')
    Message.where(messagable_type: 'Member').where(action: 'ban').joins('join members on members.id = messages.messagable_id').where("members.joinable_type = 'Issue'").update_all(action: 'ban_issue_organizer')

    Message.where(messagable_type: 'Member').where(action: 'admit').joins('join members on members.id = messages.messagable_id').where("members.joinable_type = 'Group'").update_all(action: 'admit_group_organizer')
    Message.where(messagable_type: 'Member').where(action: 'admit').joins('join members on members.id = messages.messagable_id').where("members.joinable_type = 'Issue'").update_all(action: 'admit_issue_organizer')

    Message.where(messagable_type: 'Member').where(action: 'welcome_organizer').joins('join members on members.id = messages.messagable_id').where("members.joinable_type = 'Group'").update_all(action: 'create_group_organizer')
    Message.where(messagable_type: 'Member').where(action: 'welcome_organizer').joins('join members on members.id = messages.messagable_id').where("members.joinable_type = 'Issue'").update_all(action: 'create_issue_organizer')

    Message.where(messagable_type: 'Member').where(action: 'create').joins('join members on members.id = messages.messagable_id').where("members.joinable_type = 'Group'").update_all(action: 'create_group_member')
    Message.where(messagable_type: 'Member').where(action: 'create').joins('join members on members.id = messages.messagable_id').where("members.joinable_type = 'Issue'").update_all(action: 'create_issue_member')

    Message.where(messagable_type: 'Member').where(action: 'force_default').joins('join members on members.id = messages.messagable_id').where("members.joinable_type = 'Issue'").update_all(action: 'force_default_issue')

    Message.where(messagable_type: 'Issue').where(action: 'edit_title').update_all(action: 'update_issue_title')

    Message.where(messagable_type: 'MemberRequest').where(action: 'accept').joins('join member_requests on member_requests.id = messages.messagable_id').where("member_requests.joinable_type = 'Group'").update_all(action: 'accept_group_member_request')
    Message.where(messagable_type: 'MemberRequest').where(action: 'accept').joins('join member_requests on member_requests.id = messages.messagable_id').where("member_requests.joinable_type = 'Issue'").update_all(action: 'accept_issue_member_request')

    Message.where(messagable_type: 'MemberRequest').where(action: 'request').joins('join member_requests on member_requests.id = messages.messagable_id').where("member_requests.joinable_type = 'Group'").update_all(action: 'create_group_member_request')
    Message.where(messagable_type: 'MemberRequest').where(action: 'request').joins('join member_requests on member_requests.id = messages.messagable_id').where("member_requests.joinable_type = 'Issue'").update_all(action: 'create_issue_member_request')

    Message.where(messagable_type: 'MemberRequest').where(action: 'cancel').joins('join member_requests on member_requests.id = messages.messagable_id').where("member_requests.joinable_type = 'Group'").update_all(action: 'reject_group_member_request')
    Message.where(messagable_type: 'MemberRequest').where(action: 'cancel').joins('join member_requests on member_requests.id = messages.messagable_id').where("member_requests.joinable_type = 'Issue'").update_all(action: 'reject_issue_member_request')
  end
end
