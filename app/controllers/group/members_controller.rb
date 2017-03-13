class Group::MembersController < GroupBaseController
  load_and_authorize_resource

  def index
    @myself = current_user if params[:last_id].blank? and current_group.member?(current_user)

    base = current_group.members.recent.where.not(user_id: current_user.id)
    @is_last_page = base.empty?
    @previous_last = current_group.members.with_deleted.find_by(id: params[:last_id])
    return if @previous_last.blank? and params[:last_id].present?

    @members = base.previous_of_recent(@previous_last).limit(@myself.blank? ? 12 : 11)

    @current_last = @members.last
    @users = @members.map &:user
    @is_last_page = (@is_last_page or base.previous_of_recent(@current_last).empty?)
  end

  def cancel
    @member = current_group.member_of current_user
    @member.destroy! if @member.present?
    redirect_to smart_group_url(current_group)
  end

  def ban
    @user = User.find_by id: params[:user_id]
    @member = current_group.members.find_by user: @user
    if @member.present?
      ActiveRecord::Base.transaction do
        @member.update_attributes(ban_message: params[:ban_message])
        @member.destroy
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
    @member = current_group.members.find_by user: @user
    @member.update_attributes(is_organizer: request.put?) if @member.present?

    respond_to do |format|
      format.js
    end
  end
end
