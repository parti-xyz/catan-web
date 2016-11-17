class CreatedAtAndUpdatedAtOfWatchesToMembers < ActiveRecord::Migration
  def change
    ActiveRecord::Base.transaction do
      Watch.all.each do |watch|
        user_id = watch.user_id
        issue_id = watch.issue_id
        Member.where(user_id: user_id, issue_id: issue_id).each do |member|
          member.update_columns(created_at: watch.created_at, updated_at: watch.updated_at)
        end
      end
    end
  end
end
