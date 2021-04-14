class Front::GroupsController < Front::BaseController
  def edit
    render_404 && return if current_group != Group.find(params[:id])
    render_403 && return if !current_group.organized_by?(current_user) && !current_user&.admin?

    render layout: 'front/simple'
  end

  def wake
    render_403 && return unless current_group.organized_by?(current_user)

    current_group.iced_at = nil
    if current_group.save
      flash[:notice] = '휴면을 해제했습니다.'
    else
      errors_to_flash(current_group)
    end

    turbolinks_redirect_to edit_front_group_path(current_group)
  end

  def ice
    render_403 && return unless current_group.organized_by?(current_user)

    current_group.iced_at = Time.current
    if current_group.save
      flash[:notice] = '휴면 전환했습니다.'
    else
      errors_to_flash(current_group)
    end

    turbolinks_redirect_to edit_front_group_path(current_group)
  end
end