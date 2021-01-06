class DropLandingPages < ActiveRecord::Migration[5.2]
  def up
    drop_table :landing_pages
  end

  def down
    create_table :landing_pages do |t|
      t.string :title
      t.text :body, null: false
      t.string :section, null: false
      t.timestamps null: false
    end
  end
end
