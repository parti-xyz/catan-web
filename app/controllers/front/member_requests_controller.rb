class Front::MemberRequestsController < ApplicationController
  def new
    render_404 && return if current_group.blank?
    turbolinks_redirect_to(intro_front_member_requests_path) && return unless user_signed_in?

    ensure_not_member!
    return if performed?

    render layout: 'front/simple'
  end

  def intro
    turbolinks_redirect_to(root_path) && return if user_signed_in? && current_group&.member?(current_user)
    render layout: 'front/simple'
  end

  def create
    turbolinks_redirect_to(intro_front_member_requests_path) && return unless user_signed_in?

    ensure_not_member!
    return if performed?

    if current_group.private? && helpers.cookies_get(:invitation_id).blank?
      @member_request = MemberRequest.new(joinable: current_group,
        user: current_user,
        description: params[:description],
        statement: params[:statement])

      if @member_request.save
        flash[:notice] = "#{current_group.title}에 가입 요청되었습니다."
        SendMessage.run(source: @member_request, sender: current_user, action: :create_group_member_request)
        MemberRequestMailer.deliver_all_later_on_create(@member_request)
      end
    else
      @member = MemberGroupService.new(group: current_group,
        user: current_user,
        description: params[:description],
        statement: params[:statement]).call

      if @member.persisted?
        flash[:notice] = "#{current_group.title}에 가입을 환영합니다."
        SendMessage.run(source: @member, sender: current_user, action: :create_group_member)
        MemberMailer.deliver_all_later_on_create(@member)
        destory_invitation!
      end
    end

    redirect_to root_path
  end

  def index
    render_403 && return if !user_signed_in? || !current_user.is_organizer?(current_group)

    base = current_group.member_requests.recent
    @member_requests = base.page(params[:page]).per(10).load

    render layout: 'front/simple'
  end

  def show
    render_403 && return if !user_signed_in? || !current_user.is_organizer?(current_group)

    @member_request = MemberRequest.find(params[:id])

    render layout: nil
  end

  def reject_form
    @user = User.find(params[:user_id])
    render layout: nil
  end

  private

  def ensure_not_member!
    return unless current_group.member?(current_user)

    flash[:notice] = '이미 가입한 멤버입니다.'
    destory_invitation!
    redirect_to(root_path)
  end

  def destory_invitation!
    return if helpers.cookies_get(:invitation_id).blank?

    Invitation.find_by(id: helpers.cookies_get(:invitation_id))&.destroy
    helpers.cookies_set(:invitation_id, nil)

    flash[:notice] += " 초대 수락을 완료합니다."
  end
end