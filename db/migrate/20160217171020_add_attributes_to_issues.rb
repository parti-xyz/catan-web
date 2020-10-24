class AddAttributesToIssues < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :body, :text, limit: 16.megabytes - 1
    add_column :issues, :logo, :string
    add_column :issues, :cover, :string
  end
end
