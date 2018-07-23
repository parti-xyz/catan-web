class AddTouchedAtToPosts < ActiveRecord::Migration[4.2]
  def change
    add_column :posts, :touched_at, :datetime

    reversible do |dir|
      dir.up do
        query = 'UPDATE posts SET touched_at = updated_at'
        ActiveRecord::Base.connection.execute query
        say query

        change_column_null :posts, :touched_at, false
      end
    end
  end
end
