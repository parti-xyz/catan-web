class Group::MemberRequestsController < GroupBaseController
  before_filter :authenticate_user!
  load_and_authorize_resource :member_request

  def create
    unless current_group.member?(current_user)
      @member_request.assign_attributes(joinable: current_group, user: current_user)
      if @member_request.save
        MessageService.new(@member_request, action: :request).call
        MemberRequestMailer.deliver_all_later_on_create(@member_request)
      end
    end
    redirect_to(request.referrer || smart_joinable_url(@member_requests.joinable))
  end

  def accept
    @user = User.find_by(id: params[:user_id])
    render_404 and return if @user.blank?
    redirect_to(request.referrer || group_members_path) and return if current_group.member?(@user)
    @member_request = current_group.member_requests.find_by(user: @user)
    render_404 and return if @member_request.blank?
    @member = MemberGroupService.new(group: current_group, user: @member_request.user).call
    if @member.persisted?
      MessageService.new(@member_request, sender: current_user, action: :accept).call
      MemberMailer.deliver_all_later_on_create(@member)
      MemberRequestMailer.on_accept(@member_request.id, current_user.id).deliver_later
    end

    redirect_to(request.referrer || group_members_path)
  end

  def reject
    @user = User.find_by(id: params[:user_id])
    render_404 and return if @user.blank?

    @member_request = current_group.member_requests.find_by(user: @user)
    redirect_to(request.referrer || group_members_path) and return if @member_request.blank?

    ActiveRecord::Base.transaction do
      @member_request.update_attributes(reject_message: params[:reject_message])
      @member_request.destroy
    end
    if @member_request.paranoia_destroyed?
      MessageService.new(@member_request, sender: current_user, action: :cancel).call
      MemberRequestMailer.on_reject(@member_request.id, current_user.id).deliver_later
    end

    redirect_to(request.referrer || group_members_path)
  end
end
