class AddSlugToIssues < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :slug, :string

    Issue.all.each do |issue|
      issue.set_slug
      issue.save
    end

    remove_index :issues, column: :title
    change_column_null :issues, :slug, false
  end
end
