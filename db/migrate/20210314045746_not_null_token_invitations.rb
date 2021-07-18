class NotNullTokenInvitations < ActiveRecord::Migration[5.2]
  def change
    change_column_null :invitations, :token, false
  end
end
