class AddSentClosedMessageAtToSurvey < ActiveRecord::Migration
  def up
    add_column :surveys, :sent_closed_message_at, :date

    query = <<-SQL.squish
      UPDATE surveys SET sent_closed_message_at = now()
    SQL
    ActiveRecord::Base.connection.execute query
  end

  def down
    raise '다운그레이드는 지원되지 않습니다'
  end
end
