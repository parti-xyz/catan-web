class PagesController < ApplicationController
  def landing
    render layout: 'front/simple'
  end

  def dock
    redirect_to landing_path and return unless user_signed_in?

    if params[:group_subdomain].present? && Group.exists?(slug: params[:group_subdomain])
      redirect_to root_url(subdomain: params[:group_subdomain]) and return
    end

    @groups = current_user.member_groups.sort_by_name.load
    if @groups.empty?
      redirect_to expedition_path and return
    end

    render layout: 'front/simple'
  end

  def expedition
    redirect_to landing_path and return unless user_signed_in?

    @groups = Group.hottest.memberable_and_unfamiliar(current_user)

    if params[:q].present?
      @groups = @groups.search_for(params[:q]).page(params[:page]).per(10)
      @mode = :search
    else
      @groups = @groups.limit(20).to_a.sample(5)
      @mode = :random
    end

    render layout: 'front/simple'
  end

  def privacy
    render layout: 'front/simple'
  end

  def privacy_v1
    render 'pages/privacy/v1', layout: 'front/simple'
  end

  def terms
    render layout: 'front/simple'
  end

  def terms_v1
    render 'pages/terms/v1', layout: 'front/simple'
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
