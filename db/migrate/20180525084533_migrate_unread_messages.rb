class MigrateUnreadMessages < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        query = <<-SQL.squish
          UPDATE messages
             SET read_at = NOW()
           WHERE messages.id <=
            ( SELECT users.last_read_message_id FROM users WHERE users.id = messages.user_id )
        SQL
        ActiveRecord::Base.connection.execute query
        say query
      end
    end
  end
end
