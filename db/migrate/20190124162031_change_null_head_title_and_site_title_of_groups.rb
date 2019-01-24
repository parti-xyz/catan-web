class ChangeNullHeadTitleAndSiteTitleOfGroups < ActiveRecord::Migration[5.2]
  def change
    change_column_null :groups, :head_title, true
    change_column_null :groups, :site_title, true
  end
end
