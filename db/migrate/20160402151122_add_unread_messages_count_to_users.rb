class AddUnreadMessagesCountToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :unread_messages_count, :integer, default: 0
  end
end
