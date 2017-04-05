class DropUniqIndexOfInvitations < ActiveRecord::Migration
  def change
    remove_index "invitations", name: 'unique_index_invitations'
    remove_index "invitations", ["user_id", "recipient_id", "joinable_id"]
  end
end
