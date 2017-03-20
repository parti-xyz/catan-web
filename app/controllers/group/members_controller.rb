class Group::MembersController < GroupBaseController
  load_and_authorize_resource
  before_action :only_organizer, only: [:ban, :organizer, :new_admit, :admit]

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

  def admit
    redirect_to group_members_path and return unless current_group.private?

    @not_found_recipient_codes = []
    @ambiguous_recipient_codes = []
    @has_error_recipient_codes = false
    new_members = []
    new_invitations = []

    params[:recipients].split.map(&:strip).reject(&:blank?).each do |recipient_code|
      recipient = nil
      if recipient_code.match /@/
        recipients = User.where(email: recipient_code)
        if recipients.count > 1
          @ambiguous_recipient_codes << recipient_code
          @has_error_recipient_codes = true
          next
        else recipients.count == 1
          recipient = recipients.first
        end
      else
        recipient = User.find_by(nickname: recipient_code)
      end

      next if current_group.invited?(recipient || recipient_code)
      next if current_group.member?(recipient)

      if recipient.present?
        new_members << current_group.members.build(user: recipient, admit_message: params[:message])
      elsif recipient_code.match /@/
        new_invitations << current_group.invitations.build(user: current_user, recipient_email: recipient_code, message: params[:message])
      else
        @not_found_recipient_codes << recipient_code
        @has_error_recipient_codes = true
      end
    end

    unless @has_error_recipient_codes
      @success = false
      ActiveRecord::Base.transaction do
        if current_group.save and
          current_group.member_requests.where(user: new_members.map(&:user)).destroy_all and
          current_group.invitations.where(recipient: new_members.map(&:user)).destroy_all and
          current_group.invitations.where(recipient_email: new_members.map(&:user).map(&:email)).destroy_all
          @success = true
        else
          raise ActiveRecord::Rollback
        end
      end

      if @success
        new_members.each do |member|
          MemberMailer.on_admit(member.id, current_user.id).deliver_later
          MessageService.new(member, sender: current_user, action: :admit).call
        end
        new_invitations.each do |invitation|
          InvitationMailer.invite(invitation.id).deliver_later
        end
        redirect_to group_members_path
      else
        errors_to_flash(current_group)
        render 'new_admit'
      end
    else
      flash[:error] = t('errors.messages.invitation.recipient_codes')
      render 'new_admit'
    end
  end
end
