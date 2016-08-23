class MigrateWatchedUsersToMembersInGroupParties < ActiveRecord::Migration
  def up
    ActiveRecord::Base.transaction do
      Issue.where.not(group_slug: nil).each do |issue|
        issue.watched_users.each do |user|
          Member.create!(issue: issue, user: user) unless issue.member?(user)
        end
      end
    end
  end
end
