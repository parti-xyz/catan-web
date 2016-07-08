class WikisController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource
  before_filter :load_issue

  def update
    @wiki.update_attributes(update_params)
    @wiki.wiki_histories.create(user: current_user, body: @wiki.body)
    redirect_to issue_wikis_path(@wiki.issue)
  end

  private

  def update_params
    params.require(:wiki).permit(:body)
  end

  def load_issue
    @issue = @wiki.issue if @wiki.present?
  end
end
