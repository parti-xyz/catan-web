class Admin::FeaturedIssuesController < AdminController
  load_and_authorize_resource

  def create
    if @featured_issue.save
      flash[:notice] = t('activerecord.successful.messages.created')
    else
      errors_to_flash(@featured_issue)
    end
    redirect_to admin_featured_contents_path
  end

  def update
    if @featured_issue.update_attributes(featured_issue_params)
      flash[:notice] = t('activerecord.successful.messages.created')
    else
      errors_to_flash(@featured_issue)
    end
    redirect_to admin_featured_contents_path
  end

  private

  def featured_issue_params
    params.require(:featured_issue).permit(%i{title slug body image mobile_image talk_title talk_id article_title article_id opinion_title opinion_id})
  end
end
