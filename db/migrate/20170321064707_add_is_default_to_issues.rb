class AddIsDefaultToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :is_default, :boolean, default: false
  end
end
