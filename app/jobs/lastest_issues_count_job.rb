class LatestIssuesCountJob < ApplicationJob
  include Sidekiq::Worker
  include LatestIssuesCountHelper

  def perform
    version = LatestIssuesCountHelper.current_version
    version = version + 1
    Issue.not_private.after(1.days.ago).group(:group_slug).count.each do |group_slug, count|
      group = Group.find_by(slug: group_slug)
      next if group.blank?

      group.update_columns(latest_issues_count: count, latest_issues_count_version: version)
    end

    LatestIssuesCountHelper.set_version(version)
  end
end
