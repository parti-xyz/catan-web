class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.references :user, null: false
      t.string :title, null: false
      t.string :slug, null: false
      t.text :body
      t.string :logo
      t.string :cover
      t.datetime :deleted_at
      t.string :active, default: 'on'
      t.timestamps null: false
    end

    add_index :groups, [:slug, :active], unique: true
    add_index :groups, [:title, :active], unique: true
  end
end
