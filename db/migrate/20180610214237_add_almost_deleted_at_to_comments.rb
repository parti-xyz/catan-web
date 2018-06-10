class AddAlmostDeletedAtToComments < ActiveRecord::Migration
  def change
    add_column :comments, :almost_deleted_at, :datetime
  end
end
