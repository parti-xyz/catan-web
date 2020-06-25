class AddNavbarStylesToGroups < ActiveRecord::Migration[5.2]
  def change
    add_column :groups, :navbar_bg_color, :string, default: '#421caa'
    add_column :groups, :navbar_text_color, :string, default: '#ffffff'
  end
end
