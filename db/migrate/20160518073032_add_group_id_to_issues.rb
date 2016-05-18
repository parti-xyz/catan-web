class AddGroupIdToIssues < ActiveRecord::Migration
  def change
    add_reference :issues, :group, index: true
  end
end
