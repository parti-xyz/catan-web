class AddGroupIdToIssues < ActiveRecord::Migration[4.2]
  def change
    add_reference :issues, :group, index: true
  end
end
