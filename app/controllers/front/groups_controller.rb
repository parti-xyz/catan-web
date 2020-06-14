class Front::GroupsController < Front::BaseController
  def edit
    render_404 and return if current_group != Group.find(params[:id])
    render_403 and return if !current_group.organized_by?(current_user) && !current_user&.admin?

    render layout: 'front/simple'
  end
end