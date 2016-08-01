module Postable
  extend ActiveSupport::Concern

  included do
    belongs_to :post_issue, class_name: Issue
    before_save :update_post_issue_id_before_save
    scope :in_group, ->(group) { joins(:post_issue).where('issues.group_slug = ?', (group.try(:slug) || group)) if group.present? }
  end

  def update_post_issue_id_before_save
    self.post_issue_id = self.issue_id
  end
end
