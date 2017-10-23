class AddDescriptionToMemberRequests < ActiveRecord::Migration
  def change
    add_column :member_requests, :description, :string
  end
end
