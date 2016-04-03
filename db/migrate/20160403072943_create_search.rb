class CreateSearch < ActiveRecord::Migration
  def change
    create_table :searches do |t|
      t.references :searchable, null: false, index: true, polymorphic: true
      t.text :content
      t.timestamps null: false
    end
  end
end
