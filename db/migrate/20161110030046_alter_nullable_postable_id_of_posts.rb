class AlterNullablePostableIdOfPosts < ActiveRecord::Migration[4.2]
  def change
    change_column_null(:posts, :postable_id, true)
    change_column_null(:posts, :postable_type, true)
  end
end
