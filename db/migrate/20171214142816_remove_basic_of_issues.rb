class RemoveBasicOfIssues < ActiveRecord::Migration[4.2]
  def change
    remove_column :issues, :basic, :boolean
  end
end
