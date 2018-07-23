class AddDescriptionToMemberRequests < ActiveRecord::Migration[4.2]
  def change
    add_column :member_requests, :description, :string
  end
end
