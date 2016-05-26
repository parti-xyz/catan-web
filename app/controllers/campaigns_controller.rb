class CampaignsController < ApplicationController
  before_filter :authenticate_user!, except: [:show]
  load_and_authorize_resource

  def create
    @campaign.user = current_user
    if @campaign.save
      redirect_to campaign_home_path(@campaign)
    else
      render 'new'
    end
  end

  def slug_show
    @slug = params[:slug]
    redirect_to root_path and return unless @slug.present?

    @campaign = Campaign.find_by slug: @slug
    render_404 and return unless @campaign.present?
  end

  def show
    redirect_to campaign_home_path(@campaign)
  end

  def update
    if @campaign.update_attributes(campaign_params)
      redirect_to campaign_home_path(@campaign)
    else
      render 'edit'
    end
  end

  def destroy
    @campaign.destroy
    redirect_to root_path
  end

  private

  def campaign_params
    params.require(:campaign).permit(:title, :body, :logo, :cover, :slug)
  end
end
