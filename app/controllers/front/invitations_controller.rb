class Front::InvitationsController < ApplicationController
  def index
    @invitations = Invitation.of_group(current_group).page(params[:page]).load

    render layout: 'front/simple'
  end

  def new
    @invitation = Invitation.new

    render layout: 'front/simple'
  end

  def bulk
    render_403 && return if !user_signed_in? || !current_user.is_organizer?(current_group)

    @new_invitations = []

    params[:recipients]&.split(/[,\s]+/)&.map(&:strip)&.reject(&:blank?)&.each do |recipient_code|
      invitation = current_group.invitations.build(user: current_user, recipient_code: recipient_code, message: params[:message])
      @new_invitations << invitation
    end

    if current_group.save
      @new_invitations.each do |invitation|
        InvitationMailer.invite(invitation.id).deliver_later
      end
      turbolinks_redirect_to(front_invitations_path)
    else
      render 'front/invitations/new', layout: 'front/simple', turbolinks: true
    end
  end

  def accept
    invitation = Invitation.find_by(id: params[:id])

    if invitation.blank?
      flash[:alert] = '해당 초대는 이미 승락되었거나 취소되었습니다.  더 이상 진행할 수 없습니다.'
      redirect_to(root_url(subdomain: nil)) && return
    elsif invitation.token != params[:token]
      flash[:alert] = '아주 오래 전에 초대되었거나 취소된 초대입니다. 더 이상 진행할 수 없습니다.'
      redirect_to(root_url(subdomain: invitation.joinable.group_for_invitation.subdomain)) && return
    end

    unless invitation.joinable.group_for_invitation.frontable?
      redirect_to smart_joinable_url(invitation.joinable)
      return
    end

    unless invitation.not_member?
      invitation.destroy
      turbolinks_redirect_to(smart_joinable_url(invitation.joinable), alert: '이미 가입한 멤버입니다. 초대 수락을 완료합니다.')
      return
    end

    helpers.cookies_set(:invitation_id, invitation.id)

    if user_signed_in?
      invitation.update_attributes(recipient: current_user)
    end

    turbolinks_redirect_to(new_front_member_request_url(subdomain: invitation.joinable.group_for_invitation.subdomain))
  end
end