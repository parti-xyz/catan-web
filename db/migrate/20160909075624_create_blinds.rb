class CreateBlinds < ActiveRecord::Migration[4.2]
  def change
    create_table :blinds do |t|
      t.references :user, index: true, null: false
      t.references :issue, index: true, null: false
      t.timestamps null: false
    end
  end
end
