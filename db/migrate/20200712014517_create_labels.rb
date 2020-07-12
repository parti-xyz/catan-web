class CreateLabels < ActiveRecord::Migration[5.2]
  def change
    create_table :labels do |t|
      t.references :issue, index: true, null: false
      t.string :title, null: false
      t.string :body
      t.integer :posts_count, default: 0
      t.timestamps null: false
    end
  end
end
