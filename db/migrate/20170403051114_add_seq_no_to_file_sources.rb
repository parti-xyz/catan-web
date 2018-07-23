class AddSeqNoToFileSources < ActiveRecord::Migration[4.2]
  def change
    add_column :file_sources, :seq_no, :integer, default: 0, null: false
  end
end
