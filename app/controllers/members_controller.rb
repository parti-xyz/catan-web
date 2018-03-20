class MembersController < ApplicationController
  before_action :authenticate_user!
  load_resource :issue
  load_and_authorize_resource :member, through: :issue, shallow: true

  def index
  end

  def create
    render_404 and return if @issue.private_blocked?(current_user) or @issue.frozen?
    @member = MemberIssueService.new(issue: @issue, user: current_user, need_to_message_organizer: true).call

    respond_to do |format|
      format.js
      format.html { redirect_to(request.referrer || (@member.present? ? smart_issue_home_path_or_url(@member.issue) : root_url)) }
    end
  end

  def cancel
    @member = @issue.members.find_by user: current_user
    if @member.present?
      ActiveRecord::Base.transaction do
        @member.destroy
        current_user.update_attributes(member_issues_changed_at: DateTime.now)
      end
    end
    respond_to do |format|
      format.js
      format.html { redirect_to(request.referrer || smart_issue_home_path_or_url(@member.issue)) }
    end
  end

  def ban
    @user = User.find_by id: params[:user_id]
    @member = @issue.members.find_by user: @user

    if @member.present?
      ActiveRecord::Base.transaction do
        @member.update_attributes(ban_message: params[:ban_message])
        @member.destroy
        @user.update_attributes(member_issues_changed_at: DateTime.now)
      end
      if @member.paranoia_destroyed?
        MessageService.new(@member, sender: current_user, action: :ban).call
        MemberMailer.on_ban(@member.id, current_user.id).deliver_later
      end
    end
    respond_to do |format|
      format.js
    end
  end

  def organizer
    @user = User.find_by id: params[:user_id]
    @member = @issue.members.find_by user: @user
    @member.update_attributes(is_organizer: request.put?) if @member.present?
    if @member.previous_changes["is_organizer"].present? and @member.is_organizer?
      MessageService.new(@member, sender: current_user, action: :new_organizer).call
      MemberMailer.on_new_organizer(@member.id, current_user.id).deliver_later
    end

    respond_to do |format|
      format.js
      format.html { redirect_to(request.referrer || smart_issue_home_path_or_url(@member.issue)) }
    end
  end
end
