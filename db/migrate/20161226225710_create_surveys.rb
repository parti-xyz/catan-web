class CreateSurveys < ActiveRecord::Migration
  def change
    create_table :surveys do |t|
      t.integer :feedbacks_counts, default: 0
      t.timestamps null: false
    end
  end
end
