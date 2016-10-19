class Admin::MonitorsController < AdminController
  def index
    @issue_tags = ActsAsTaggableOn::Tag.where('taggings.taggable_type': 'Issue').joins(:taggings).select('name').distinct
  end
end
