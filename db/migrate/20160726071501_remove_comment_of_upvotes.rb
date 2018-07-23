class RemoveCommentOfUpvotes < ActiveRecord::Migration[4.2]
  def up
    Upvote.all.each do |upvote|
      upvote.update_columns upvotable_id: upvote.comment_id, upvotable_type: 'Comment'
    end
    add_index :upvotes, [:user_id, :upvotable_id, :upvotable_type], unique: true
    change_column_null :upvotes, :upvotable_id, false
    change_column_null :upvotes, :upvotable_type, false
    remove_column :upvotes, :comment_id
  end

  def down
    raise "unimplemented"
  end
end
