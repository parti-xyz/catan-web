class RemoveCategorySlugOfIssues < ActiveRecord::Migration[4.2]
  def change
    remove_columns :issues, :category_slug
  end
end
