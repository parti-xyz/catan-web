class CreateBlinds < ActiveRecord::Migration
  def change
    create_table :blinds do |t|
      t.references :user, index: true, null: false
      t.references :issue, index: true, null: false
      t.timestamps null: false
    end
  end
end
