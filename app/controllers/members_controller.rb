class MembersController < ApplicationController
  before_filter :authenticate_user!
  load_resource :issue
  load_and_authorize_resource :member, through: :issue, shallow: true

  def create
    render_404 and return if @issue.private_blocked?(current_user)

    @member.user = current_user
    ActiveRecord::Base.transaction do
      if @member.save
        @member.issue.member_requests.find_by(user: @member.user).try(:destroy)
      end
    end
    if @member.persisted?
      MessageService.new(@member).call
      MemberMailer.deliver_all_later_on_create(@member)
    end

    respond_to do |format|
      format.js
      format.html { redirect_to(request.referrer || smart_issue_home_path_or_url(@member.issue)) }
    end
  end

  def cancel
    @member = @issue.members.find_by user: current_user
    if @member.present? and !@member.issue.made_by?(current_user)
      @member.destroy
    end
    respond_to do |format|
      format.js
      format.html { redirect_to(request.referrer || smart_issue_home_path_or_url(@member.issue)) }
    end
  end

  def ban
    @user = User.find_by id: params[:user_id]
    @member = @issue.members.find_by user: @user
    @member.try(:destroy)
    respond_to do |format|
      format.js
    end
  end
end
