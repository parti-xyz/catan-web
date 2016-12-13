class AddFreezedAtToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :freezed_at, :datetime
  end
end
