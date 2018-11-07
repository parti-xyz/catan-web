class CreateIssuePostsFormats < ActiveRecord::Migration[5.2]
  def change
    create_table :issue_posts_formats do |t|
      t.references :group_home_component, null: false, index: true
      t.references :issue, null: false, index: true
      t.timestamp null: false
    end
  end
end
