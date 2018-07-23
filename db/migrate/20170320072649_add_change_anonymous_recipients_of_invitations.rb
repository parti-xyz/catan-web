class AddChangeAnonymousRecipientsOfInvitations < ActiveRecord::Migration[4.2]
  def change
    change_column_null :invitations, :recipient_id, true
    add_column :invitations, :recipient_email, :string
  end
end
