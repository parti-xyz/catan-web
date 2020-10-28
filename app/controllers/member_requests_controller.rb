class MemberRequestsController < ApplicationController
  before_action :authenticate_user!
  load_resource :issue
  load_and_authorize_resource :member_request, through: :issue, shallow: true

  def create
    render_404 and return if @issue.member?(current_user) or @issue.frozen?

    @member_request.user = current_user
    if @member_request.save
      SendMessage.run(source: @member_request, sender: current_user, action: :create_issue_member_request)
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
    redirect_to(request.referrer || smart_issue_members_path(@member.issue)) if @issue.member?(@user)

    @member_request = @issue.member_requests.find_by(user: @user)
    render_404 and return if @member_request.blank?

    @member = MemberIssueService.new(issue: @issue, user: @member_request.user, need_to_message_organizer: true, is_force: true).call
    if @member.try(:persisted?)
      @member_request.try(:destroy)
      SendMessage.run(source: @member_request, sender: current_user, action: :accept_issue_member_request)
      MemberRequestMailer.on_accept(@member_request.id, current_user.id).deliver_later
    end

    redirect_to(request.referrer || smart_issue_members_path(@member.issue))
  end

  def reject_form
    @user = User.find_by id: params[:user_id]
  end

  def reject
    @user = User.find_by(id: params[:user_id])
    render_404 and return if @user.blank?

    @member_request = @issue.member_requests.find_by(user: @user)
    render_404 and return if @member_request.blank?

    ActiveRecord::Base.transaction do
      @member_request.update_attributes(reject_message: params[:reject_message])
      @member_request.destroy
    end
    if @member_request.paranoia_destroyed?
      SendMessage.run(source: @member_request, sender: current_user, action: :reject_issue_member_request)
      MemberRequestMailer.on_reject(@member_request.id, current_user.id).deliver_later
    end

    respond_to do |format|
      format.js
      format.html { redirect_to(request.referrer || smart_joinable_url(@member_request.joinable)) }
    end
  end
end
