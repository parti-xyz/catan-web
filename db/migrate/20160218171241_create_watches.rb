class CreateWatches < ActiveRecord::Migration[4.2]
  def change
    create_table :watches do |t|
      t.references :issue, null: false, index: true
      t.references :user, null: false, index: true
      t.timestamps null: false
    end

    add_index :watches, [:user_id, :issue_id], unique: true

    add_column :issues, :watches_count, :integer, default: 0
  end
end
