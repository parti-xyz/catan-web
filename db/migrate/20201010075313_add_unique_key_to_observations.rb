class AddUniqueKeyToObservations < ActiveRecord::Migration[5.2]
  def change
    remove_index :root_observations, :group_id
    add_index :root_observations, :group_id, unique: true

    add_index :group_observations, [:user_id, :group_id], unique: true
    add_index :issue_observations, [:user_id, :issue_id], unique: true
    add_index :post_observations, [:user_id, :post_id], unique: true
  end
end
