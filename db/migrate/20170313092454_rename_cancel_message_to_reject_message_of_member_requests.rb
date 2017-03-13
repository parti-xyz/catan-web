class RenameCancelMessageToRejectMessageOfMemberRequests < ActiveRecord::Migration
  def change
    rename_column :member_requests, :cancel_message, :reject_message
  end
end
