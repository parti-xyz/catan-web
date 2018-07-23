class AddLastTouchedAtToIssues < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :last_touched_at, :datetime
  end
end
