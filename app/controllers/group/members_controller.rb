class Group::MembersController < Group::BaseController
  load_and_authorize_resource
  before_action :only_organizer, only: [:ban, :organizer, :new_admit, :admit]
  before_action :authenticate_user!, except: [:magic_form]

  def index
    base = current_group.members.recent
    base = smart_search_for(base, params[:keyword], profile: (:admin if user_signed_in? and current_user.admin?)) if params[:keyword].present?
    @members = base.page(params[:page]).per(4 * 10)
  end

  def cancel
    @member = current_group.member_of current_user
    ActiveRecord::Base.transaction do
      @member.destroy! if @member.present?
      current_group.issues.each do |issue|
        issue.members.find_by(user: current_user).try(:destroy)
      end
    end
    redirect_to smart_group_url(current_group)
  end

  def ban_form
    @user = User.find_by id: params[:user_id]
  end

  def ban
    @user = User.find_by id: params[:user_id]
    @member = current_group.members.find_by user: @user
    if @member.present?
      ActiveRecord::Base.transaction do
        @member.update_attributes(ban_message: params[:ban_message])
        @member.destroy
        current_group.issues.each do |issue|
          issue.members.find_by(user: @user).try(:destroy)
        end
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
    if @member.previous_changes["is_organizer"].present? and @member.is_organizer?
      MessageService.new(@member, sender: current_user, action: :new_organizer).call
      MemberMailer.on_new_organizer(@member.id, current_user.id).deliver_later
    end

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

    params[:recipients].split(/[,\s]+/).map(&:strip).reject(&:blank?).each do |recipient_code|
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
          current_group.default_issues.each do |issue|
            new_members.each do |member|
              MemberIssueService.new(issue: issue, user: member.user, need_to_message_organizer: false, is_force: true).call
            end
          end
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

  def magic_link
    current_group.magic_key = SecureRandom.hex
    current_group.save

    redirect_to :edit_magic_link_group_members
  end

  def delete_magic_link
    current_group.magic_key = nil
    current_group.save

    redirect_to :edit_magic_link_group_members
  end

  def magic_form
    unless user_signed_in?
      flash[:info] = t('devise.failure.unauthenticated')
      redirect_to new_user_session_path and return
    end

    redirect_to  root_path and return if current_group.member?(current_user)

    if current_group.magic_key != params[:key]
      flash[:error] = t('errors.messages.invalid_group_magic_key')
      redirect_to  root_path and return
    end
  end

  def magic_join
    redirect_to root_path and return if current_group.member?(current_user)
    if current_group.magic_key != params[:key]
      flash[:error] = t('errors.messages.invalid_group_magic_key')
      redirect_to root_path and return
    end

    @member = MemberGroupService.new(group: current_group, user: current_user).call
    if @member.persisted?
      flash[:success] = t('views.group.welcome')
      MessageService.new(@member).call
      MemberMailer.deliver_all_later_on_create(@member)
    end

    redirect_to root_path
  end

  def update_profile
    member = current_group.member_of current_user
    member.description = params[:description] if member.present?
    if member.save
      flash[:success] = '그룹 내 프로필이 변경되었습니다.'
    else
      flash[:error] = t('errors.messages.unknown')
    end
    redirect_to group_members_path
  end

  def invite_issues_form
    @user = User.find_by(id: params[:user_id])
    render_404 and return if @user.blank?

    authorize! :invite_group_issues, @user
  end

  def invite_issues
    @user = User.find_by(id: params[:user_id])
    render_404 and return if @user.blank?

    authorize! :invite_group_issues, @user

    @issues = Issue.where(id: params[:issue_ids])

    ActiveRecord::Base.transaction do
      @issues.each do |issue|
        member = MemberIssueService.new(issue: issue, user: @user, need_to_message_organizer: true, is_force: true).call
        if !member.try(:persisted?) and !issue.reload.member?(@user)
          flash[:error] = t('errors.messages.unknown')
          raise ActiveRecord::Rollback
          break
        end
      end
    end

    if flash[:error].blank?
      flash[:success] = '초대했습니다.'
    end
    redirect_to invite_issues_form_group_members_path(user_id: params[:user_id])
  end
end
