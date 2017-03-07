class Group::MembersController < GroupBaseController
  load_and_authorize_resource

  def index
    redirect_to root_path and return if private_blocked?(current_group)

    @myself = current_user if params[:last_id].blank? and current_group.member?(current_user)

    base = current_group.member_users.recent.where.not(id: current_user.id)
    @is_last_page = base.empty?
    previous_last = current_group.member_users.with_deleted.find_by(id: params[:last_id])
    @users = base.previous_of_recent(previous_last).limit(@myself.blank? ? 12 : 11)

    @current_last = @users.last
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
    @member.try(:destroy)
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

  def private_blocked?(group)
    group.private_blocked?(current_user)
  end
end
