class AddIssueCreationPrivilegesToGroups < ActiveRecord::Migration[5.2]
  def change
    add_column :groups, :issue_creation_privileges, :string, default: 'member', null: false
  end
end
