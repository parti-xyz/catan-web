class RenameCancelMessageToRejectMessageOfMemberRequests < ActiveRecord::Migration[4.2]
  def change
    rename_column :member_requests, :cancel_message, :reject_message
  end
end
