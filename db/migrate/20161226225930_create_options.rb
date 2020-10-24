class CreateOptions < ActiveRecord::Migration[4.2]
  def change
    create_table :options do |t|
      t.references :survey, null: false, index: true
      t.text :body, limit: 16.megabytes - 1
      t.integer :feedbacks_counts, default: 0
      t.timestamps null: false
    end
  end
end
