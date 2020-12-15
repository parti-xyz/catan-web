class AddIsHtmlToComments < ActiveRecord::Migration[5.2]
  def change
    add_column :comments, :is_html, :boolean, default: false
  end
end
