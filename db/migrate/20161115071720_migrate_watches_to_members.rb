class MigrateWatchesToMembers < ActiveRecord::Migration
  def up
    ActiveRecord::Base.transaction do
      Watch.all.each do |watch|
        if Issue.exists?(watch.issue_id) and User.exists?(watch.user_id)
          Member.find_or_create_by!(issue_id: watch.issue_id, user_id: watch.user_id)
        end
      end
    end
  end
end

