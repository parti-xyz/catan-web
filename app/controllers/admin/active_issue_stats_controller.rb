class Admin::ActiveIssueStatsController < AdminController
  def index
    stat_at = params[:stat_at] || Date.yesterday
    @active_issue_stats = ActiveIssueStat.by_day(stat_at, field: :stat_at)
  end
end
