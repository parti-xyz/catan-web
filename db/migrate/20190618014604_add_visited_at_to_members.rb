class AddVisitedAtToMembers < ActiveRecord::Migration[5.2]
  def change
    add_column :members, :visited_at, :datetime
  end
end
