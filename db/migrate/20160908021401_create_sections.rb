class CreateSections < ActiveRecord::Migration
  def change
    create_table :sections do |t|
      t.string :name, null: false, index: true
      t.references :issue, null: false, index: true
      t.timestamps null: false
    end
  end
end
