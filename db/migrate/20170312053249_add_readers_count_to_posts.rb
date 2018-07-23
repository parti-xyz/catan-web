class AddReadersCountToPosts < ActiveRecord::Migration[4.2]
  def change
    add_column :posts, :readers_count, :integer, default: 0
  end
end
