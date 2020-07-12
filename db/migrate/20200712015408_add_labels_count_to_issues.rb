class AddLabelsCountToIssues < ActiveRecord::Migration[5.2]
  def change
    add_column :issues, :labels_count, :integer, default: 0
  end
end
