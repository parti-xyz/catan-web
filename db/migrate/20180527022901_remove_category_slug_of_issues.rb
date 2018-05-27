class RemoveCategorySlugOfIssues < ActiveRecord::Migration
  def change
    remove_columns :issues, :category_slug
  end
end
