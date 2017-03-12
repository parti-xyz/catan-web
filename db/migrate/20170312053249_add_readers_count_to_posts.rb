class AddReadersCountToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :readers_count, :integer, default: 0
  end
end
