class MigrationFormatNameOfGroupHomeComponents < ActiveRecord::Migration[5.2]
  def change
    transaction do
      execute "UPDATE group_home_components SET format_name = 'issue_posts_hottest' WHERE format_name = 'issue_posts';"
    end
  end
end
