class AddUpvotableToUpvotes < ActiveRecord::Migration
  def change
    add_reference :upvotes, :upvotable, polymorphic: true

    change_column_null :upvotes, :comment_id, true
    remove_index :upvotes, [:user_id, :comment_id]
  end
end
