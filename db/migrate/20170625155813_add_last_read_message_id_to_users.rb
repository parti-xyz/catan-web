class AddLastReadMessageIdToUsers < ActiveRecord::Migration
  def up
    add_column :users, :last_read_message_id, :integer, default: 0

    reversible do |dir|
      dir.up do
        User.all.each do |user|
          unread_messages_count = user.unread_messages_count
          unread_messages_count = 0 if unread_messages_count.blank?
          user.update_columns(last_read_message_id: user.messages.recent.limit(user.unread_messages_count + 1).last)
        end
      end
    end
  end
end
