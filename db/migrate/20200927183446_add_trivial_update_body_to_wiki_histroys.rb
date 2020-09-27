class AddTrivialUpdateBodyToWikiHistroys < ActiveRecord::Migration[5.2]
  def change
    add_column :wiki_histories, :trivial_update_body, :boolean, default: false, null: false
  end
end
