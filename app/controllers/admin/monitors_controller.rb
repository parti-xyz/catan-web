class Admin::MonitorsController < Admin::BaseController
  def index
    @statistics = Statistics.recent.limit(100)

    @user_join_month = User.with_deleted.group_by_month(:created_at, last: 24, reverse: true, format: "%Y-%m").count
    @user_join_week = User.with_deleted.group_by_week(:created_at, last: 24, reverse: true).count
    @group_week = Group.with_deleted.group_by_week(:created_at, last: 24, reverse: true).count
  end
end
