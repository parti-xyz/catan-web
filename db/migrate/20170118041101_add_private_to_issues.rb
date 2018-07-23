class AddPrivateToIssues < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :private, :boolean, default: false, null: false
  end
end
