class AddNoticeOnlyToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :notice_only, :boolean, default: false
  end
end
