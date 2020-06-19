class AddCloudPlanToGroups < ActiveRecord::Migration[5.2]
  def change
    add_column :groups, :cloud_plan, :boolean, default: false
  end
end
