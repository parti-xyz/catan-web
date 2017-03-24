class AddSentClosedMessageAtToSurvey < ActiveRecord::Migration
  def change
    add_column :surveys, :sent_closed_message_at, :date

    query = <<-SQL.squish
      UPDATE surveys SET sent_closed_message_at = now()
    SQL
    ActiveRecord::Base.connection.execute query

  end
end
