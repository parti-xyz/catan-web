class Front::MembersController < Front::BaseController
  def index
    base = current_group.members.recent
    if params[:keyword].present?
      base = smart_search_for(base, params[:keyword], profile: (:admin if current_user&.admin?))
    end
    @members = base.page(params[:page]).per(10).load

    render layout: 'front/simple'
  end

  def show
    @member = Member.find(params[:id])

    render layout: 'front/simple'
  end

  def statement
    render_403 and return if !user_signed_in? || !(current_group.organized_by?(current_user) || current_user.admin?)
    @member = Member.find(params[:id])
    render layout:  nil
  end

  def edit_me
    @member = current_group.member_of(current_user)
    render_404 and return if @member.blank?

    render layout: 'front/simple'
  end

  def update_me
    @member = current_group.member_of(current_user)
    render_404 and return if @member.blank?

    @member.update_attributes(params.permit(:role, :description, :statement))

    flash[:notice] = I18n.t('activerecord.successful.messages.created')
    turbolinks_redirect_to root_url(current_group.subdomain)
  end

  def user
    @user = User.find(params[:user_id])
    @member = current_group.member_of(@user)
    render layout: nil
  end

  def ban_form
    @user = User.find(params[:user_id])
    render layout: nil
  end
end