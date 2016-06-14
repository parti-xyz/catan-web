class WikisController < ApplicationController
  def update
    issue = Issue.find(params['wiki']['issue_id'])
    @wiki = issue.wiki
    @wiki.update_attributes(update_params)
    redirect_to issue_wikis_path(issue)
  end

  private

  def update_params
    params.require(:wiki).permit(:body)
  end
end
