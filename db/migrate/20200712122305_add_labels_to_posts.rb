class AddLabelsToPosts < ActiveRecord::Migration[5.2]
  def change
    remove_columns :posts, :bulletpoint
    add_reference :posts, :label, null: true, index: true
  end
end
