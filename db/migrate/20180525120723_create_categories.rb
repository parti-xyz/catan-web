class CreateCategories < ActiveRecord::Migration
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.string :group_slug, null: false, index: true
      t.timestamps null: false
    end

    add_index :categories, [:group_slug, :name], unique: true, name: 'categories_uniq'
  end
end
