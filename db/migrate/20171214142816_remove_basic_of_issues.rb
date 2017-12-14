class RemoveBasicOfIssues < ActiveRecord::Migration
  def change
    remove_column :issues, :basic, :boolean
  end
end
