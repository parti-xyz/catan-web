class DropRootAsDashboardOfUsers < ActiveRecord::Migration
  def change
    remove_column :users, :root_as_dashboard
  end
end
