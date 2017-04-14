class AddExpiresAtToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :expires_at, :datetime, index: true

    query = <<-SQL.squish
      UPDATE surveys SET expires_at = DATE_ADD(created_at, INTERVAL duration DAY)
    SQL
    ActiveRecord::Base.connection.execute query
  end
end
