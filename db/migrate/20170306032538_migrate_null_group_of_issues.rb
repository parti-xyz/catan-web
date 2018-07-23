class MigrateNullGroupOfIssues < ActiveRecord::Migration[4.2]
  def up
    query = <<-SQL.squish
      UPDATE issues
         SET group_slug = 'indie'
       WHERE group_slug = '' or group_slug is null
    SQL
    ActiveRecord::Base.connection.execute query
    change_column_null :issues, :group_slug, false
  end
end
