class AddVisitableToUsers < ActiveRecord::Migration[5.2]
  def change
    remove_column :members, :visited_at

    add_column :users, :last_visitable_id, :integer
    add_column :users, :last_visitable_type, :string
  end
end
