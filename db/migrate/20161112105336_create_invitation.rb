class CreateInvitation < ActiveRecord::Migration[4.2]
  def change
    create_table :invitations do |t|
      t.references :user, null: false, index: true
      t.references :recipient, null: false, index: true
      t.references :issue, null: false, index: true
      t.timestamps null: false
    end

    add_index :invitations, [:user_id, :recipient_id, :issue_id], unique: true
  end
end
