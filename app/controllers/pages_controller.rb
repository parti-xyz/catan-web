class PagesController < ApplicationController
  def home
    @featured_contents = []
    @featured_contents << FeaturedIssue.all
    @featured_contents << FeaturedCampaign.all
    @featured_contents.shuffle
    @issues = Issue.all.order(:title)
  end

  def about
  end

  def robots
    respond_to :text
    expires_in 6.hours, public: true
  end

  def stat
    StatisticsJob.perform_async
    redirect_to root_path
  end

  def components
  end
end
