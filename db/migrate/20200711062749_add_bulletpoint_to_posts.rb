class AddBulletpointToPosts < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :bulletpoint, :string
  end
end
