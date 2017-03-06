class MemberRequestsController < ApplicationController
  before_filter :authenticate_user!
  load_resource :issue
  load_and_authorize_resource :member_request, through: :issue, shallow: true

  def create
    render_404 and return if @issue.member?(current_user)

    @member_request.user = current_user
    if @member_request.save
      MessageService.new(@member_request).call
      MemberRequestMailer.deliver_all_later_on_create(@member_request)
    end
    respond_to do |format|
      format.js
      format.html { redirect_to(request.referrer || smart_joinable_url(@member_request.joinable)) }
    end
  end

  def accept
    @user = User.find_by(id: params[:user_id])
    render_404 and return if @user.blank?
    redirect_to(request.referrer || smart_issue_users_path(@member.issue)) if @issue.member?(@user)

    @member_request = @issue.member_requests.find_by(user: @user)
    render_404 and return if @member_request.blank?

    @member = @issue.members.build(user: @member_request.user)
    ActiveRecord::Base.transaction do
      if @member.save
        @member_request.try(:destroy)
      end
    end
    if @member.persisted?
      MessageService.new(@member_request, sender: current_user, action: :accept).call
      MemberMailer.deliver_all_later_on_create(@member)
      MemberRequestMailer.on_accept(@member_request.id, current_user.id).deliver_later
    end

    redirect_to(request.referrer || smart_issue_users_path(@member.issue))
  end

  def reject
    @user = User.find_by(id: params[:user_id])
    render_404 and return if @user.blank?

    @member_request = @issue.member_requests.find_by(user: @user)
    render_404 and return if @member_request.blank?

    ActiveRecord::Base.transaction do
      @member_request.update_attributes(cancel_message: params[:cancel_message])
      @member_request.destroy
    end
    if @member_request.paranoia_destroyed?
      MessageService.new(@member_request, sender: current_user, action: :cancel).call
      MemberRequestMailer.on_cancel(@member_request.id, current_user.id).deliver_later
    end

    respond_to do |format|
      format.js
      format.html { redirect_to(request.referrer || smart_joinable_url(@member_request.joinable)) }
    end
  end
end
