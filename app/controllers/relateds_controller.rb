class RelatedsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_related_with_issues, only: :new
  load_and_authorize_resource

  def new
    if params[:issue_id].present?
      @issue = Issue.find params[:issue_id]
      @related = @issue.relateds.build
    else
      redirect_to root_path
    end
  end

  def create
    begin
      parsed = Rails.application.routes.recognize_path params[:target_issue_url]
      related_target = Issue.find_by slug: parsed[:slug]
      related_target = nil if related_target.try(:private_blocked?, current_user)
    rescue ActionController::RoutingError => e
      related_target = nil
    end

    @issue = @related.issue
    if related_target.blank?
      flash[:notice] = t('activerecord.errors.messages.not_found_parti')
      render 'new' and return
    end

    @related.target = related_target
    if @related.save
      redirect_to @related.issue
    else
      errors_to_flash(@related)
      render 'new'
    end
  end

  def destroy
    @related.destroy
    redirect_to smart_issue_home_path_or_url(@related.issue)
  end

  private

  def create_params
    params.require(:related).permit(:issue_id)
  end

  def load_related_with_issues
    issue = Issue.find(params[:issue_id])
    @related = Related.new(issue: issue)
  end
end
