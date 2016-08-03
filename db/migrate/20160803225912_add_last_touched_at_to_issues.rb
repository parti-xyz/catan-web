class AddLastTouchedAtToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :last_touched_at, :datetime
  end
end
