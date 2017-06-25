class AddExpiresAtToSurveys < ActiveRecord::Migration
  def up
    add_column :surveys, :expires_at, :datetime, index: true

    query = <<-SQL.squish
      UPDATE surveys SET expires_at = DATE_ADD(created_at, INTERVAL duration DAY)
    SQL
    ActiveRecord::Base.connection.execute query
  end
  def down
    raise '다운그레이드는 지원되지 않습니다'
  end
end
