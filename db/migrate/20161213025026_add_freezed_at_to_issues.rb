class AddFreezedAtToIssues < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :freezed_at, :datetime
  end
end
