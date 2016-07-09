class RelatedsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_related_with_issues, only: :new
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
    @related.target = Issue.find_by title: params[:target_title]
    @issue = @related.issue
    unless @related.target.present?
      flash[:notice] = t('activerecord.errors.messages.not_found_parti')
      render 'new'
      return
    end
    if @related.save
      redirect_to @related.issue
    else
      errors_to_flash(@related)
      render 'new'
    end
  end

  def destroy
    @related.destroy
    redirect_to issue_home_path(@related.issue)
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
