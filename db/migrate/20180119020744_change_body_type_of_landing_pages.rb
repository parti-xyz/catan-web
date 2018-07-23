class ChangeBodyTypeOfLandingPages < ActiveRecord::Migration[4.2]
  def change
    change_column :landing_pages, :body, :text
  end
end
