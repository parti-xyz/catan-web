class RenameLastTouchedAtToLastStrokedAtIssues < ActiveRecord::Migration[4.2]
  def change
    rename_column :issues, :last_touched_at, :last_stroked_at
    add_reference :issues, :last_stroked_user, null: true, index: true
  end
end
