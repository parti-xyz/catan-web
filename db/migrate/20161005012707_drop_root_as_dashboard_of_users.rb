class DropRootAsDashboardOfUsers < ActiveRecord::Migration[4.2]
  def change
    remove_column :users, :root_as_dashboard
  end
end
