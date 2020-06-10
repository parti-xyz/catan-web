class AddFrontableToGroups < ActiveRecord::Migration[5.2]
  def change
    add_column :groups, :frontable, :boolean, default: false, null: false
  end
end
