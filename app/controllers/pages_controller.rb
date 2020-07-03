class PagesController < ApplicationController
  def authenticated_home
    redirect_to discover_root_path and return unless user_signed_in?
    redirect_to dashboard_url(subdomain: nil)
  end

  def about
  end

  def pricing
    redirect_to about_path
  end

  def privacy_v1
    render 'pages/privacy/v1'
  end

  def terms_v1
    render 'pages/terms/v1'
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

  def discover
    @sections = LandingPage.all_data
    @subjects = LandingPage.where("section like 'subject%'").to_a
  end

  def components
  end

  def share_telegram
    render layout: false
  end
end
