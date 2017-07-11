class GroupDestroyService

  attr_accessor :issue
  attr_accessor :current_user

  def initialize(group_slug)
    @group = Group.with_deleted.find_by slug: group_slug
  end

  def call
    return if @group.blank?

    ActiveRecord::Base.transaction do
      Message.where(messagable: @group.members_with_deleted).destroy_all
      Message.where(messagable: @group.member_requests_with_deleted).destroy_all
      @group.destroy!
    end
  end
end
