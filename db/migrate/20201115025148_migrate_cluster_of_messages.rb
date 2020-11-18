class MigrateClusterOfMessages < ActiveRecord::Migration[5.2]
  class Message < ActiveRecord::Base
  end

  def up
    Message.where(action: 'upvote').joins("INNER JOIN upvotes ON messages.messagable_id = upvotes.id AND upvotes.upvotable_type = 'Post'").update_all('messages.cluster_owner_id = upvotes.upvotable_id, messages.cluster_owner_type = upvotes.upvotable_type')

    Message.where(action: 'upvote').joins("INNER JOIN upvotes ON messages.messagable_id = upvotes.id AND upvotes.upvotable_type = 'Comment'").joins('INNER JOIN comments ON upvotes.upvotable_id = comments.id').update_all("messages.cluster_owner_id = comments.post_id, messages.cluster_owner_type = 'Post'")

    Message.where(action: 'create_comment').joins('inner join comments on messages.messagable_id = comments.id').update_all("messages.cluster_owner_id = comments.post_id, messages.cluster_owner_type = 'Post'")

    Message.where(action: 'mention').where(messagable_type: 'Comment').joins('inner join comments on messages.messagable_id = comments.id').update_all("messages.cluster_owner_id = comments.post_id, messages.cluster_owner_type = 'Post'")

    Message.where(id: Message.where(action: 'create_announcement').to_a).joins('inner join posts on messages.messagable_id = posts.announcement_id').update_all("messages.cluster_owner_id = posts.id, messages.cluster_owner_type = 'Post'")

    Message.where(messagable_type: 'Survey').joins('inner join posts on messages.messagable_id = posts.survey_id').update_all("messages.cluster_owner_id = posts.id, messages.cluster_owner_type = 'Post'")

    Message.where(cluster_owner_id: nil).update_all('cluster_owner_id = messagable_id, cluster_owner_type = messagable_type')

    Message.where(action: 'admit_group_organizer').update_all(action: 'assign_group_organizer')
    Message.where(action: 'admit_issue_organizer').update_all(action: 'assign_issue_organizer')
  end
end
