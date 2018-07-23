class AddAttributesToIssues < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :body, :text
    add_column :issues, :logo, :string
    add_column :issues, :cover, :string
  end
end
