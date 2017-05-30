class AddLastStrokedForToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :last_stroked_for, :string
  end
end
