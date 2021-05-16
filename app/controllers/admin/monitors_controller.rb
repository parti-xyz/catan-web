class Admin::MonitorsController < Admin::BaseController
  def index
    @statistics = Statistics.recent.limit(100)

    @user_join_statistics = User.with_deleted.group_by_month(:created_at, last: 24, reverse: true, format: "%Y %m").count
  end
end
