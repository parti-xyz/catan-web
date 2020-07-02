class AddNavbarCocStylesToGroups < ActiveRecord::Migration[5.2]
  def change
    add_column :groups, :navbar_coc_text_color, :string, default: '#5e2abb'
  end
end
