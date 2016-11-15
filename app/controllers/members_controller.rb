class MembersController < ApplicationController
  before_filter :authenticate_user!
  load_resource :issue
  load_and_authorize_resource :member, through: :issue, shallow: true

  def create
    @member.user = current_user
    if @member.save
      MessageService.new(@member).call
      MemberMailer.on_create(@member.id).deliver_later
    end
    respond_to do |format|
      format.js
      format.html { redirect_to(request.referrer || issue_home_path_or_url(@member.issue)) }
    end
  end

  def cancel
    @member = @issue.members.find_by user: current_user
    if @member.present? and !@member.issue.made_by?(current_user)
      @member.destroy
    end
    respond_to do |format|
      format.js
      format.html { redirect_to(request.referrer || issue_home_path_or_url(@member.issue)) }
    end
  end
end
