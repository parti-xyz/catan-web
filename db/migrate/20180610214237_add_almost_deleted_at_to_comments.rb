class AddAlmostDeletedAtToComments < ActiveRecord::Migration[4.2]
  def change
    add_column :comments, :almost_deleted_at, :datetime
  end
end
