class CreateMembers < ActiveRecord::Migration
  def change
    create_table :members do |t|
      t.references :issue, null: false, index: true
      t.references :user, null: false, index: true
      t.timestamps null: false
    end

    add_index :members, [:user_id, :issue_id], unique: true

    add_column :issues, :members_count, :integer, default: 0
  end
end
