class CreateMakers < ActiveRecord::Migration
  def change
    create_table :makers do |t|
      t.references :user, null: false, index: true
      t.references :issue, null: false, index: true
      t.timestamps null: false
    end

    add_index :makers, [:user_id, :issue_id], unique: true
  end
end
