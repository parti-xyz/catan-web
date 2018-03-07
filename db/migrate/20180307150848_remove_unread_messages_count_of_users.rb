class RemoveUnreadMessagesCountOfUsers < ActiveRecord::Migration
  def change
    remove_column :users, :unread_messages_count
  end
end
