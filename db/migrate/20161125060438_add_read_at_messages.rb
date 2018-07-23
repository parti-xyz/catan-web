class AddReadAtMessages < ActiveRecord::Migration[4.2]
  def change
    add_column :messages, :read_at, :datetime

    reversible do |dir|
      dir.up do
        query = <<-SQL.squish
          UPDATE messages
             SET read_at = NOW()
        SQL
        ActiveRecord::Base.connection.execute query
        say query
      end
    end
  end
end
