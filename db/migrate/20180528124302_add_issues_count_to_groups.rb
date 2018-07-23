class AddIssuesCountToGroups < ActiveRecord::Migration[4.2]
  def change
    add_column :groups, :issues_count, :integer, default: 0

    reversible do |dir|
      dir.up do
        Group.find_each { |group| Group.reset_counters(group.id, :issues) }
      end
    end
  end
end
