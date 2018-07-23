class RemoveTouchedAttributesOfPosts < ActiveRecord::Migration[4.2]
  def change
    remove_column :posts, :touched_at, :datetime, null: false
    remove_column :posts, :last_touched_action, :string, default: 'create'
    remove_column :posts, :last_touched_params, :string
  end
end
