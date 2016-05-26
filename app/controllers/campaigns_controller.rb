class CampaignsController < ApplicationController
  before_filter :authenticate_user!, except: [:show, :slug_show]
  load_and_authorize_resource

  def create
    @campaign.user = current_user
    build_issues

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
    @campaign.assign_attributes(campaign_params)
    build_issues
    if @campaign.save
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
    params.require(:campaign).permit(:title, :body, :logo, :cover, :slug, :issue_slugs)
  end

  def build_issues
    @campaign.campaigned_issues.destroy_all if @campaign.persisted?
    return if @campaign.issue_slugs.blank?
    @campaign.issue_slugs.split(",").map(&:strip).each do |issue_slug|
      issue = Issue.find_by(slug: issue_slug)
      if issue.present?
        @campaign.campaigned_issues.build(issue: issue)
      end
    end
  end
end
