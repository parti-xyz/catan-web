class ChangeBodyTypeOfLandingPages < ActiveRecord::Migration
  def change
    change_column :landing_pages, :body, :text
  end
end
