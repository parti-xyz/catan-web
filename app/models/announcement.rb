class Announcement < ApplicationRecord
  has_one :post, dependent: :nullify
  has_many :audiences, dependent: :destroy do
    def merge_nickname
      self.map { |audience| audience.member.user.nickname }.join(',')
    end
  end
  has_one :current_user_audience,
    -> { where(member_id: Current.group.member_of(Current.user)) },
    class_name: "Audience"
  has_many :messages, as: :messagable, dependent: :destroy
  accepts_nested_attributes_for :audiences, reject_if: proc { |attributes|
    attributes['member_id'].try(:strip).blank?
  }
  scope :of_group, -> (group) { where(id: Post.of_group(group).select(:announcement_id)) }

  extend Enumerize
  enumerize :announcing_mode, in: [:all, :direct], predicates: true, scope: true
  attr_accessor :direct_announced_user_nicknames

  def smart_audiences_count
    if announcing_mode.all?
      post.issue.group.members_count
    else
      self.audiences_count
    end
  end

  def smart_need_to_notice_members_count
    smart_audiences_count - noticed_audiences_count
  end

  def smart_need_to_notice_members
    if announcing_mode.all?
      post.issue.group.members.where.not(id: audiences.noticed.select('member_id')).includes(:user)
    else
      post.issue.group.members.where(id: audiences.need_to_notice.select(:member_id)).includes(:user)
    end
  end

  def post_for_message
    post
  end

  def issue_for_message
    post.issue
  end

  def group_for_message
    post.issue.group
  end

  def self.messagable_group_method
    :of_group
  end

  def noticed_all?
    smart_audiences_count == noticed_audiences_count
  end

  def need_to_notice? someone
    return false unless requested_to_notice? someone
    !noticed?(someone)
  end

  def noticed? someone
    return false if someone.blank?
    group_member = someone.smart_group_member(post.issue.group)
    return false if group_member.blank?

    return current_user_audience.noticed? if someone == Current.user && current_user_audience.present?
    audiences.find_by(member: group_member)&.noticed?
  end

  def requested_to_notice? someone
    return false if someone.blank?
    group_member = someone.smart_group_member(post.issue.group)
    return false if group_member.blank?

    return true if announcing_mode.all?

    return true if someone == Current.user && current_user_audience.present?
    audiences.exists?(member: group_member)
  end

  def stopped?
    self.stopped_at.present?
  end
end
