class PagesController < ApplicationController
  def home
    if current_group.blank?
      @issues = Issue.unfreezed.hottest
    else
      @issues = Issue.unfreezed.displayable_in_current_group(current_group).recent_touched
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
