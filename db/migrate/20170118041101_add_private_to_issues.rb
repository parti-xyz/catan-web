class AddPrivateToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :private, :boolean, default: false, null: false
  end
end
