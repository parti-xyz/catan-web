class AddTitleToLandingPages < ActiveRecord::Migration[4.2]
  def change
    add_column :landing_pages, :title, :string, null: true
  end
end
