class CreatePolls < ActiveRecord::Migration
  def change
    create_table :polls do |t|
      t.string :title, null: false
      t.timestamps null: false
      t.references :talk, index: true
    end
  end
end
