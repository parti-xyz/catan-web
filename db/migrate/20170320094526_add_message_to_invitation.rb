class AddMessageToInvitation < ActiveRecord::Migration[4.2]
  def change
    add_column :invitations, :message, :text
  end
end
