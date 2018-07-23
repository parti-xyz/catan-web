class CreateActiveIssueStats < ActiveRecord::Migration[4.2]
  def change
    create_table :active_issue_stats do |t|
      t.references :issue, null: false, index: true
      t.date :stat_at, null: false, index: true
      t.integer :new_posts_count, default: 0
      t.integer :new_comments_count, default: 0
      t.timestamp null: false
    end
  end
end
