class AddRootAsDashboardToUsers < ActiveRecord::Migration
  def change
    add_column :users, :root_as_dashboard, :boolean, default: false
  end
end
