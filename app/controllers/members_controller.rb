class MembersController < ApplicationController
  before_filter :authenticate_user!
  load_resource :issue
  load_and_authorize_resource :member, through: :issue, shallow: true

  def create
    ActiveRecord::Base.transaction do
      @member.user = current_user
      if @member.save
        @watch = Watch.new(user: current_user, issue: @issue)
        @watch.save
      end
    end

    respond_to do |format|
      format.js
      format.html { redirect_to issue_home_path_or_url(@member.issue) }
    end
  end

  def cancel
    @member = @issue.members.find_by user: current_user
    if @member.present? and !@member.issue.made_by?(current_user)
      ActiveRecord::Base.transaction do
        if @member.destroy
          @watch = @issue.watches.find_by user: current_user
          @watch.destroy if @watch.present?
        end
      end
    end

    respond_to do |format|
      format.js
      format.html { redirect_to issue_home_path_or_url(@member.issue) }
    end
  end
end
