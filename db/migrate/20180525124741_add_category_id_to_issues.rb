class AddCategoryIdToIssues < ActiveRecord::Migration
  def change
    add_reference :issues, :category, index: true
  end
end
