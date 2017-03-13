class AddBanMessageToMembers < ActiveRecord::Migration
  def change
    add_column :members, :ban_message, :text
  end
end
