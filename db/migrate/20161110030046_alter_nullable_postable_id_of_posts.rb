class AlterNullablePostableIdOfPosts < ActiveRecord::Migration[4.2]
  def change
    change_column_null(:posts, :postable_id, true)
  end
end
