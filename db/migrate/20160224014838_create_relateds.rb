class CreateRelateds < ActiveRecord::Migration[4.2]
  def change
    create_table :relateds do |t|
      t.references :issue, null: false, index: true
      t.references :target, null: false, index: true
      t.timestamps null: false
    end

    add_index :relateds, [:issue_id, :target_id], unique: true
  end
end
