class Announcement < ApplicationRecord
  include Messagable

  has_one :post, dependent: :nullify
  has_many :audiences, dependent: :destroy do
    def merge_nickname
      self.map { |audience| audience.member.user.nickname }.join(',')
    end
  end
  has_one :current_user_audience,
    -> { where(member_id: Current.user&.members) },
    class_name: "Audience"
  accepts_nested_attributes_for :audiences, reject_if: proc { |attributes|
    attributes['member_id'].try(:strip).blank?
  }
  scope :of_group, -> (group) { where(id: Post.of_group(group).select(:announcement_id)) }

  extend Enumerize
  attr_accessor :direct_announced_user_nicknames

  def cached_audiences_count
    @_cached_audiences_count ||= post.issue.group.members_count
    @_cached_audiences_count
  end

  def cached_need_to_notice_members_count
    cached_audiences_count - noticed_audiences_count
  end

  def smart_need_to_notice_members
    post.issue.group.members.where.not(id: audiences.noticed.select('member_id')).includes(:user)
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

  def self.of_group_for_message(group)
    self.of_group(group)
  end

  def cached_noticed_all?
    cached_audiences_count == noticed_audiences_count
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

    true
  end

  def stopped?
    self.stopped_at.present?
  end
end
