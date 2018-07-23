class CreateTalksAgain < ActiveRecord::Migration[4.2]
  def change
    create_table :talks do |t|
      t.string :title, null: false
      t.datetime :deleted_at
      t.timestamps null: false
    end
  end
end
