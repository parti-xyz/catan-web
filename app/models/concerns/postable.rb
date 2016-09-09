module Postable
  extend ActiveSupport::Concern

  included do
    belongs_to :post_issue, class_name: Issue
    before_save :update_post_issue_id_before_save
    scope :only_group_or_all_if_blank, ->(group) { joins(:post_issue).where('issues.group_slug = ?', group.slug) if group.present? }
    scope :of_issue, ->(issue) { where(issue_id: issue) }
    scope :hottest, -> { joins(:post).merge(Post.hottest) }
    scope :previous_of_hottest, ->(postable) { joins(:post).merge(Post.previous_of_hottest(postable.try(:acting_as))) }
  end

  def update_post_issue_id_before_save
    self.post_issue_id = self.issue_id
  end
end
