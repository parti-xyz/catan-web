class AddCategoryIdToIssues < ActiveRecord::Migration[4.2]
  def change
    add_reference :issues, :category, index: true
  end
end
