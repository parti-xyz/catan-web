class AddParentToComments < ActiveRecord::Migration[4.2]
  def change
    add_reference :comments, :parent, index: true
  end
end
