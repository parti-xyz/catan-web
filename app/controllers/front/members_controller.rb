class Front::MembersController < Front::BaseController
  def edit_me
    @member = current_group.member_of(current_user)
    render_404 and return if @member.blank?

    render layout: 'front/simple'
  end

  def update_me
    @member = current_group.member_of(current_user)
    render_404 and return if @member.blank?

    @member.update_attributes(params.permit(:description))

    redirect_to root_url(current_group.subdomain), turbolinks: :true
  end
end