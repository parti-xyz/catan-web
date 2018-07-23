class AddAdmitMessageToMembers < ActiveRecord::Migration[4.2]
  def change
    add_column :members, :admit_message, :text
  end
end
