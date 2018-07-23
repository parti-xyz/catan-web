class CreateLandingPages < ActiveRecord::Migration[4.2]
  def change
    create_table :landing_pages do |t|
      t.string :body, null: false
      t.string :section, unique: true, null: false
      t.timestamps null: false
    end
  end
end
