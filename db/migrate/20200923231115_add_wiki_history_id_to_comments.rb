class AddWikiHistoryIdToComments < ActiveRecord::Migration[5.2]
  def change
    add_reference :comments, :wiki_history, null: true, index: true
  end
end
