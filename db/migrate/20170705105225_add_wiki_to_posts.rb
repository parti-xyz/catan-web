class AddWikiToPosts < ActiveRecord::Migration
  def change
    add_reference :posts, :wiki, null: true, index: true
  end
end
