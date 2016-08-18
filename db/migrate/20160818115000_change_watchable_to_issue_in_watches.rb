class ChangeWatchableToIssueInWatches < ActiveRecord::Migration
   def up
    add_reference :watches, :issue, index: true

    query = "UPDATE watches SET issue_id = watchable_id"
    ActiveRecord::Base.connection.execute query
    say query

    remove_index :watches, name: 'index_watches_on_watchable_type_and_watchable_id'
    remove_index :watches, name: 'index_watches_on_user_id_and_watchable_id_and_watchable_type'
    remove_column :watches, :watchable_id
    remove_column :watches, :watchable_type

    change_column_null :watches, :issue_id, false
    add_index :watches, [:user_id, :issue_id], unique: true

    remove_column :campaigns, :watches_count
  end

  def down
    raise "unimplemented"
  end
end
