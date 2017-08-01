class MembersController < ApplicationController
  before_filter :authenticate_user!
  load_resource :issue
  load_and_authorize_resource :member, through: :issue, shallow: true

  def create
    render_404 and return if @issue.private_blocked?(current_user) or @issue.frozen?
    @member = MemberIssueService.new(issue: @issue, user: current_user, is_auto: false).call

    respond_to do |format|
      format.js
      format.html { redirect_to(request.referrer || smart_issue_home_path_or_url(@member.issue)) }
    end
  end

  def cancel
    @member = @issue.members.find_by user: current_user
    if @member.present? and !@member.issue.organized_by?(current_user)
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

    respond_to do |format|
      format.js
    end
  end
end
