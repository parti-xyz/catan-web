class DropNotes < ActiveRecord::Migration[4.2]
  def change
    drop_table :notes
  end
end
