class AddCanceledAtOfUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :canceled_at, :datetime
  end
end
