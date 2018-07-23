class AddCategorySlugToIssues < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :category_slug, :string
  end
end
