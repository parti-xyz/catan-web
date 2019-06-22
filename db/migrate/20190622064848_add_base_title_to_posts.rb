class AddBaseTitleToPosts < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :base_title, :string
  end
end
