class AddDeletedAtToNotes < ActiveRecord::Migration
  def change
    add_column :notes, :deleted_at, :datetime, index: true
  end
end
