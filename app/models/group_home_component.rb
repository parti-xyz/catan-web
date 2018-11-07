class GroupHomeComponent < ApplicationRecord
  belongs_to :group
  has_one :issue_posts_format, dependent: :destroy, class_name: 'GroupHomeComponentPreference::IssuePostsFormat'

  accepts_nested_attributes_for :issue_posts_format, reject_if: proc { |attributes|
    attributes['issue_id'].blank?
  }

  extend Enumerize
  enumerize :format_name, in: [:updated_issues, :all_posts, :issue_posts], predicates: true, scope: true

  validates :issue_posts_format, presence: true, if: Proc.new { |c| c.format_name.issue_posts? }, on: :update

  scope :sequenced, -> { order(:seq_no) }
end
