class AddPositionToIssues < ActiveRecord::Migration[5.2]
  def change
    add_column :issues, :position, :integer, null: false, default: 0
  end
end
