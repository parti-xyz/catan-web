class AddBanMessageToMembers < ActiveRecord::Migration[4.2]
  def change
    add_column :members, :ban_message, :text
  end
end
