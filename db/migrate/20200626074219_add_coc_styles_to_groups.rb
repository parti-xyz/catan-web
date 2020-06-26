class AddCocStylesToGroups < ActiveRecord::Migration[5.2]
  def change
    add_column :groups, :coc_text_color, :string, default: '#5e2abb'
    add_column :groups, :coc_btn_bg_color, :string, default: '#5e2abb'
    add_column :groups, :coc_btn_text_color, :string, default: '#ffffff'
  end
end
