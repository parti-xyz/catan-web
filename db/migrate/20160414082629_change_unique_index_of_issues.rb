class ChangeUniqueIndexOfIssues < ActiveRecord::Migration
  def up
    add_column :issues, :active, :string, default: 'on'

    query = "UPDATE issues SET active = (CASE WHEN deleted_at IS NULL THEN 'on' ELSE NULL END)"
    ActiveRecord::Base.connection.execute query
    say query

    remove_index :issues, name: "index_issues_on_slug_and_deleted_at"
    remove_index :issues, name: "index_issues_on_title_and_deleted_at"
    add_index :issues, [:slug, :active], unique: true
    add_index :issues, [:title, :active], unique: true
  end

  def down
    raise "unimplemented"
  end
end
