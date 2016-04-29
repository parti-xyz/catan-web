class PagesController < ApplicationController
  def home
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
end
