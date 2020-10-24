class CreateDecisionHistories < ActiveRecord::Migration[4.2]
  def change
    create_table :decision_histories do |t|
      t.references :post, null: false, index: true
      t.references :user, null: true, index: true
      t.text :body, limit: 16.megabytes - 1
      t.timestamps null: false
    end
  end
end
