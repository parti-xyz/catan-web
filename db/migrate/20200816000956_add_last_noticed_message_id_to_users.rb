class AddLastNoticedMessageIdToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :last_noticed_message_id, :Integer
  end
end
