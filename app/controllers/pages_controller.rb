class PagesController < ApplicationController
  def index
    if user_signed_in? and current_user.root_as_dashboard?
      redirect_to dashboard_path
    else
      redirect_to action: :home
    end
  end

  def home
    if current_group.blank?
      @featured_contents = []
      @featured_contents << FeaturedCampaign.all.to_a
      @featured_contents << FeaturedIssue.all.to_a
      @featured_contents.flatten!.compact!
      @issues = Issue.all.recent_touched
    else
      @issues = Issue.only_group_or_all_if_blank(current_group).recent_touched
      render 'group_home'
    end
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
