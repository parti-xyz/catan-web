class AddSeqNoToFileSources < ActiveRecord::Migration
  def change
    add_column :file_sources, :seq_no, :integer, default: 0, null: false
  end
end
