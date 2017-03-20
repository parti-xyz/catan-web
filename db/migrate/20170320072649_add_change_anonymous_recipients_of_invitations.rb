class AddChangeAnonymousRecipientsOfInvitations < ActiveRecord::Migration
  def change
    change_column_null :invitations, :recipient_id, true
    add_column :invitations, :recipient_email, :string
  end
end
