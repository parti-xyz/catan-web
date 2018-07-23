class AddDescriptionToMember < ActiveRecord::Migration[4.2]
  def change
    add_column :members, :description, :text
  end
end
