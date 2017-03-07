class AddUserToOptions < ActiveRecord::Migration
  def change
    add_reference :options, :user, index: true, null: true

    query = <<-SQL.squish
      UPDATE options SET user_id = (SELECT user_id FROM posts WHERE posts.survey_id = options.survey_id limit 1)
    SQL
    ActiveRecord::Base.connection.execute query
    change_column_null :options, :user_id, false
  end
end
