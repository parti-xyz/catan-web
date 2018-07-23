class AddMessagesReadAtToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :messages_read_at, :datetime
    reversible do |dir|
      dir.up do
        execute "UPDATE users SET messages_read_at = (SELECT MAX(messages.created_at) FROM messages WHERE messages.user_id = users.id)"
      end
    end
    remove_column :users, :last_read_message_id
  end
end
