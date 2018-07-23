class CreateSurveys < ActiveRecord::Migration[4.2]
  def change
    create_table :surveys do |t|
      t.integer :feedbacks_counts, default: 0
      t.timestamps null: false
    end
  end
end
