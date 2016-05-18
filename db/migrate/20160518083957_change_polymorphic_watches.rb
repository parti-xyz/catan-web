class ChangePolymorphicWatches < ActiveRecord::Migration
  def up
    add_reference :watches, :watchable, index: true, polymorphic: true

    query = "UPDATE watches SET watchable_id = issue_id, watchable_type = 'Issue'"
    ActiveRecord::Base.connection.execute query
    say query

    remove_index :watches, name: 'index_watches_on_user_id_and_issue_id'
    remove_column :watches, :issue_id
    change_column_null :watches, :watchable_id, false
    change_column_null :watches, :watchable_type, false

    add_index :watches, [:user_id, :watchable_id, :watchable_type], unique: true
  end

  def down
    raise "unimplemented"
  end
end
