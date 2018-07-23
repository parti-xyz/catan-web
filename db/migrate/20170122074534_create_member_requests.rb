class CreateMemberRequests < ActiveRecord::Migration[4.2]
  def change
    create_table :member_requests do |t|
      t.references :issue, null: false, index: true
      t.references :user, null: false, index: true
      t.datetime :deleted_at
      t.string :active, default: "on"
      t.text :cancel_message
      t.timestamps null: false
    end

    add_index :member_requests, [:issue_id, :user_id, :active], unique: true
  end
end
