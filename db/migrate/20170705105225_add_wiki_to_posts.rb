class AddWikiToPosts < ActiveRecord::Migration[4.2]
  def change
    add_reference :posts, :wiki, null: true, index: true
  end
end
