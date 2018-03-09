class Admin::MonitorsController < Admin::BaseController
  def index
    @issue_tags = ActsAsTaggableOn::Tag.where('taggings.taggable_type': 'Issue').joins(:taggings).select('name').distinct
    @statistics = Statistics.recent.limit(50)
  end
end
