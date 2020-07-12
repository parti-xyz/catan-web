class Front::FoldersController < Front::BaseController
  def form
    issue = Issue.find(params[:channel_id])
    redirect_to slug_issue_folders_path(slug: issue.slug), turbolinks: false
  end
end