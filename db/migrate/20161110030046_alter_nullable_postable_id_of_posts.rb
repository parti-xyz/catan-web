class AlterNullablePostableIdOfPosts < ActiveRecord::Migration
  def change
    change_column_null(:posts, :postable_id, true)
  end
end
