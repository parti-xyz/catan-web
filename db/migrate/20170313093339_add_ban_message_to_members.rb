class AddBanMessageToMembers < ActiveRecord::Migration[4.2]
  def change
    add_column :members, :ban_message, :text, limit: 16.megabytes - 1
  end
end
