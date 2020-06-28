class IssueReadAllPosts < ActiveInteraction::Base
  integer :user_id
  integer :issue_id
  integer :limit

  validates :user_id, presence: true
  validates :issue_id, presence: true

  def execute
    current_user = User.find_by(id: user_id)
    if current_user.blank?
      errors.add(:user, :not_found)
      return
    end
    current_issue = Issue.find_by(id: issue_id)
    if current_issue.blank?
      errors.add(:issue, :not_found)
      return
    end
    unless current_issue.group&.member?(current_user)
      errors.add(:user, :not_member)
      return
    end

    target_posts = current_issue.posts.need_to_read_only(current_user)

    if limit.present? && target_posts.count > limit
      errors.add(:limit, :too_many_posts_to_read)
      return
    end

    target_posts.each do |post|
      post.read!(current_user)
    end
    current_issue.read!(current_user)
  end
end
