class PagesController < ApplicationController
  def home
    if current_group.blank?
      @issues = Issue.unfreezed.hottest
    else
      @issues = Issue.unfreezed.only_group_or_all_if_blank(current_group).recent_touched
      render 'group_home'
    end
  end

  def about
  end

  def robots
    respond_to :text
    expires_in 6.hours, public: true
  end

  def score
    ScoreJob.perform_async
    redirect_to root_path
  end

  def analyze
    AnalyzeJob.perform_async
    redirect_to root_path
  end

  def components
  end


end
