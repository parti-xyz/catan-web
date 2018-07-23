class ChangeTypeOfSentClosedMessageAtOfSurveys < ActiveRecord::Migration[4.2]
  def up
    change_column :surveys, :sent_closed_message_at, :datetime
    query = <<-SQL.squish
      UPDATE surveys SET sent_closed_message_at = DATE_ADD(DATE_ADD(created_at, INTERVAL duration DAY), INTERVAL 1 HOUR) WHERE sent_closed_message_at is not NULL
    SQL
    ActiveRecord::Base.connection.execute query
  end
  def down
    raise '다운그레이드는 지원되지 않습니다'
  end
end
