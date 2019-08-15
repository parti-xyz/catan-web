class AddPinnedByToPosts < ActiveRecord::Migration[5.2]
  def change
    add_reference :posts, :pinned_by, default: :null, index: true
  end
end
