class CreateMergedIssues < ActiveRecord::Migration[4.2]
  def change
    create_table :merged_issues do |t|
      t.references :source, null: false, index: true
      t.string :source_slug, null: false, index: true
      t.references :issue, null: false, index: true
      t.references :user, null: false, index: true
      t.timestamps null: false
    end

    add_index :merged_issues, [:source_id, :issue_id], unique: true
  end
end
