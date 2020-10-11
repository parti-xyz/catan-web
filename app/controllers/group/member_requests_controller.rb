class Group::MemberRequestsController < Group::BaseController
  before_action :authenticate_user!
  load_and_authorize_resource :member_request

  def create
    unless current_group.member?(current_user)
      if current_group.private?
        @member_request.assign_attributes(joinable: current_group, user: current_user, description: params[:description], statement: params[:statement])
        if @member_request.save
          flash[:success] = "#{current_group.title}에 가입을 환영합니다"
          SendMessage.run(source: @member_request, sender: current_user, action: :create_group_member_request)
          MemberRequestMailer.deliver_all_later_on_create(@member_request)
        end
      else
        @member = MemberGroupService.new(group: current_group, user: current_user, description: params[:description], statement: params[:statement]).call

        if @member.persisted?
          flash[:success] = "#{current_group.title}에 가입을 환영합니다"
          SendMessage.run(source: @member, sender: current_user, action: :create_group_member)
          MemberMailer.deliver_all_later_on_create(@member)
        end
      end
    end

    if helpers.explict_front_namespace?
      redirect_to root_path
    else
      redirect_to(request.referrer || smart_joinable_url(@member_requests.joinable))
    end
  end

  def accept
    @user = User.find_by(id: params[:user_id])
    render_404 and return if @user.blank?
    redirect_to(request.referrer || group_members_path) and return if current_group.member?(@user)
    @member_request = current_group.member_requests.find_by(user: @user)
    render_404 and return if @member_request.blank?
    @member = MemberGroupService.new(group: current_group, user: @member_request.user, description: @member_request.description, statement: @member_request.statement).call
    if @member.persisted?
      SendMessage.run(source: @member_request, sender: current_user, action: :accept_group_member_request)
      MemberMailer.deliver_all_later_on_create(@member)
      MemberRequestMailer.on_accept(@member_request.id, current_user.id).deliver_later
    end

    redirect_to(request.referrer || group_members_path)
  end

  def reject_form
    @user = User.find_by id: params[:user_id]
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
      SendMessage.run(source: @member_request, sender: current_user, action: :reject_group_member_request)
      MemberRequestMailer.on_reject(@member_request.id, current_user.id).deliver_later
    end

    redirect_to(request.referrer || group_members_path)
  end
end
