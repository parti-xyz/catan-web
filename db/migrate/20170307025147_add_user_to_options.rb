class AddUserToOptions < ActiveRecord::Migration
  def up
    add_reference :options, :user, index: true, null: true

    query = <<-SQL.squish
      UPDATE options SET user_id = (SELECT user_id FROM posts WHERE posts.survey_id = options.survey_id limit 1)
    SQL
    ActiveRecord::Base.connection.execute query
    change_column_null :options, :user_id, false
  end

  def down
    raise '다운그레이드는 지원되지 않습니다'
  end
end
