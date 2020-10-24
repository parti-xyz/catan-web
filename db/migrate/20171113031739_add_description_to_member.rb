class AddDescriptionToMember < ActiveRecord::Migration[4.2]
  def change
    add_column :members, :description, :text, limit: 16.megabytes - 1
  end
end
