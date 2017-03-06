class MigrateMakersToMembers < ActiveRecord::Migration
  def up
    add_column :members, :is_organizer, :boolean, default: false, null: false
    query = <<-SQL.squish
      UPDATE  members
         SET  is_organizer = true
       WHERE  ( user_id, joinable_id, joinable_type )
              IN (
                SELECT user_id, makable_id, makable_type
                  FROM makers
              )
    SQL
    ActiveRecord::Base.connection.execute query
    drop_table :makers
  end

  def down
    raise '다운그레이드는 지원되지 않습니다'
  end
end
