class GroupReadAllPosts < ActiveInteraction::Base
  integer :user_id
  integer :group_id
  integer :limit

  validates :user_id, presence: true
  validates :group_id, presence: true

  def execute
    current_user = User.find_by(id: user_id)
    if current_user.blank?
      errors.add(:user, :not_found)
      return
    end
    current_group = Group.find_by(id: group_id)
    if current_group.blank?
      errors.add(:group, :not_found)
      return
    end
    unless current_group.member?(current_user)
      errors.add(:user, :not_member)
      return
    end

    current_group_accessible_only_issues = current_group.issues.accessible_only(current_user)

    target_posts = Post.where(issue: current_group_accessible_only_issues).need_to_read_only(current_user)

    if limit.present? && target_posts.count > limit
      errors.add(:limit, :too_many_posts_to_read)
      return
    end

    issue_ids = []
    target_posts.each do |post|
      post.read!(current_user)
      issue_ids << post.issue_id
    end
    current_group.issues.accessible_only(current_user).where(id: issue_ids).each do |issue|
      issue.read!(current_user)
    end
  end
end
