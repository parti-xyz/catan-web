class CreateFileSource < ActiveRecord::Migration[4.2]
  def change
    create_table :file_sources do |t|
      t.string :name, null: false
      t.string :attachment, null: false
      t.string :file_type, null: false
      t.integer :file_size, null: false
      t.timestamps null: false
    end
  end
end
