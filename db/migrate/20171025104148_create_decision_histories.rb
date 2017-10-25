class CreateDecisionHistories < ActiveRecord::Migration
  def change
    create_table :decision_histories do |t|
      t.references :post, null: false, index: true
      t.references :user, null: true, index: true
      t.text :body
      t.timestamps null: false
    end
  end
end
