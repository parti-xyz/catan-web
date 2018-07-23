class AddRootAsDashboardToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :root_as_dashboard, :boolean, default: false
  end
end
