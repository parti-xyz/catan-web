class AddCategorySlugToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :category_slug, :string
  end
end
