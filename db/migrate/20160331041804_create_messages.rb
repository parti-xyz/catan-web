class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.references :user, null: false, index: true
      t.references :messagable, null: false, index: true, polymorphic: true
      t.timestamps null: false
    end
  end
end
