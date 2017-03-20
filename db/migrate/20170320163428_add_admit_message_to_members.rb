class AddAdmitMessageToMembers < ActiveRecord::Migration
  def change
    add_column :members, :admit_message, :text
  end
end
