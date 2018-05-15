class Admin::ActiveIssueStatsController < Admin::BaseController
  def index
    @stat_at = params[:stat_at].try(:to_date) || Date.yesterday
    @active_issue_stats = ActiveIssueStat.by_day(@stat_at, field: :stat_at).reject{ |i| i.issue.blank? }.group_by { |i| i.issue.group_slug }
  end
end
