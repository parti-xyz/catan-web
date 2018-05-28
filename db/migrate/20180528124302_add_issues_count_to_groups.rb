class AddIssuesCountToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :issues_count, :integer, default: 0

    reversible do |dir|
      dir.up do
        Group.find_each { |group| Group.reset_counters(group.id, :issues) }
      end
    end
  end
end
