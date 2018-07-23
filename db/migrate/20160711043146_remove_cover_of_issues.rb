class RemoveCoverOfIssues < ActiveRecord::Migration[4.2]
  def change
    remove_column :issues, :cover
  end
end
