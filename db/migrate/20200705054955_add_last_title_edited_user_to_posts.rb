class AddLastTitleEditedUserToPosts < ActiveRecord::Migration[5.2]
  def change
    add_reference :posts, :last_title_edited_user, null: true
  end
end
