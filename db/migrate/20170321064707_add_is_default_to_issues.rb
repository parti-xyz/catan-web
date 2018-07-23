class AddIsDefaultToIssues < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :is_default, :boolean, default: false
  end
end
