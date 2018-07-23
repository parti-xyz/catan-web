class MigrateDefaultSections < ActiveRecord::Migration[4.2]
  def up
    query = <<-SQL.squish
      INSERT INTO sections(name, issue_id, created_at, updated_at)
           SELECT '기본', id, created_at, created_at
             FROM issues
    SQL
    ActiveRecord::Base.connection.execute query
    say query
  end
end
