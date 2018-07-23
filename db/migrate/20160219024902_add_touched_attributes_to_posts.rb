class AddTouchedAttributesToPosts < ActiveRecord::Migration[4.2]
  def change
    add_column :posts, :last_touched_action, :string, default: 'create'
    add_column :posts, :last_touched_params, :string
  end
end
