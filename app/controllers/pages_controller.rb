class PagesController < ApplicationController
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

  def share_telegram
    render layout: false
  end
end
