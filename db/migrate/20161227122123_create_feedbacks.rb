class CreateFeedbacks < ActiveRecord::Migration
  def change
    create_table :feedbacks do |t|
      t.references :user, null: false, index: true
      t.references :survey, null: false, index: true
      t.references :option, null: false, index: true
      t.timestamps null: false
    end

    add_index :feedbacks, [:user_id, :survey_id], unique: true
  end
end
