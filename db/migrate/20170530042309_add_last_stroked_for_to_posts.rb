class AddLastStrokedForToPosts < ActiveRecord::Migration[4.2]
  def change
    add_column :posts, :last_stroked_for, :string
  end
end
