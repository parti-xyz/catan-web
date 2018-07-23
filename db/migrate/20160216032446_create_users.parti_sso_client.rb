# This migration comes from parti_sso_client (originally 20151212033148)
class CreateUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :users do |t|
      t.string :email, null: false, index: true
      t.timestamps null: false
    end
  end
end
