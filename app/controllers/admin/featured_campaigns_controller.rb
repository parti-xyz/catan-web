class Admin::FeaturedCampaignsController < AdminController
  load_and_authorize_resource

  def create
    if @featured_campaign.save
      flash[:notice] = t('activerecord.successful.messages.created')
    else
      errors_to_flash(@featured_campaign)
    end
    redirect_to admin_featured_contents_path
  end

  def update
    if @featured_campaign.update_attributes(featured_campaign_params)
      flash[:notice] = t('activerecord.successful.messages.created')
    else
      errors_to_flash(@featured_campaign)
    end
    redirect_to admin_featured_contents_path
  end

  private

  def featured_campaign_params
    params.require(:featured_campaign).permit(%i{title url body image mobile_image})
  end
end
