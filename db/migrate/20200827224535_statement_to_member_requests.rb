class StatementToMemberRequests < ActiveRecord::Migration[5.2]
  def change
    add_column :member_requests, :statement, :text
  end
end
