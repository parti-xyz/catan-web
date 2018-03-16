class Group::ConfigurationsController < Group::BaseController
  skip_before_action :verify_current_group, only: [:new, :create]
  before_action :authenticate_user!
  before_action :only_organizer, only: [:edit, :update]

  def new
    @group = Group.new
    @group.user = current_user
    @group.members.build(user: current_user, is_organizer: true)
  end

  def create
    @group = Group.new(group_params)
    @group.plan = Group.plan.lite
    @group.user = current_user
    @group.slug = params[:group][:slug]
    @group.members.build(user: current_user, is_organizer: true)

    if @group.save
      redirect_to root_url(subdomain: @group.subdomain)
    else
      render 'new'
    end
  end

  def edit
    @group = current_group
  end

  def update
    @group = current_group
    @group.assign_attributes(group_params)

    new_organizer_members = []
    ActiveRecord::Base.transaction do
      if params[:group].has_key?(:organizer_nicknames)
        organizer_users = User.parse_nicknames(@group.organizer_nicknames)
        organizer_users.each do |user|
          member = @group.members.find_by(user: user)
          if member.blank?
            if @group.comprehensive_joined_by?(user)
              member = MemberGroupService.new(group: @group, user: user).call
            else
              next
            end
          end

          unless member.is_organizer?
            member.update_attributes(is_organizer: true)
            new_organizer_members << member
          end
        end
        @group.organizer_members.each do |member|
          member.update_attributes(is_organizer: false) unless organizer_users.include? member.user
        end
      end

      if @group.save
        #그룹 변경 노티 필요
        #MessageService.new(@group, sender: current_user).call
        old_organizer_members = @group.organizer_members.to_a - new_organizer_members
        new_organizer_members.each do |member|
          next if member.user == current_user
          MessageService.new(member, sender: current_user, action: :new_organizer).call(old_organizer_members: old_organizer_members)
          MemberMailer.on_new_organizer(member.id, current_user.id).deliver_later
        end
        flash[:success] = t('activerecord.successful.messages.created')
        redirect_to root_url(subdomain: @group.subdomain)
      else
        errors_to_flash @group
        render 'edit'
      end
    end
  end

  private

  def group_params
    # 민감한 정보인 slug은 따로 받습니다
    params.require(:group).permit(:title, :site_description, :site_title,
      :head_title, :site_keywords, :private, :organizer_nicknames)
  end
end
