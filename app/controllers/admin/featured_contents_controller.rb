class Admin::FeaturedContentsController < AdminController
  def index
    @featured_issues = FeaturedIssue.all
    @featured_campaigns = FeaturedCampaign.all
  end
end
