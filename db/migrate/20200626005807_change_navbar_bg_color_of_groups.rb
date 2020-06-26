class ChangeNavbarBgColorOfGroups < ActiveRecord::Migration[5.2]
  def change
    change_column_default :groups, :navbar_bg_color, '5e2abb'
  end
end
