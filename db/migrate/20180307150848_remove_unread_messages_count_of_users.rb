class RemoveUnreadMessagesCountOfUsers < ActiveRecord::Migration[4.2]
  def change
    remove_column :users, :unread_messages_count
  end
end
