class AddNoticeOnlyToIssues < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :notice_only, :boolean, default: false
  end
end
