class AddTitleToLandingPages < ActiveRecord::Migration
  def change
    add_column :landing_pages, :title, :string, null: true
  end
end
