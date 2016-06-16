class PagesController < ApplicationController
  def home
    @featured_contents = []
    @featured_contents << FeaturedCampaign.all.to_a
    @featured_contents << FeaturedIssue.all.to_a
    @featured_contents.flatten!.compact!
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
