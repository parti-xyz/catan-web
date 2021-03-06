class Upvote < ApplicationRecord
  include Messagable

  belongs_to :user
  belongs_to :upvotable, polymorphic: true, counter_cache: true
  belongs_to :issue

  validates :user, presence: true
  validates :upvotable, presence: true
  validates :user, uniqueness: {scope: [:upvotable_id, :upvotable_type]}

  scope :recent, -> { order(id: :desc) }
  scope :sequential, -> { order(created_at: :asc) }
  scope :previous_of, ->(id) { where('id < ?', id) if id.present? }
  scope :latest, -> { after(1.day.ago) }
  scope :by_issue, ->(issue) { where(issue: issue) }
  scope :comment_only, -> { where(upvotable_type: 'Comment') }
  scope :of_group, -> (group) {
    where(upvotable_type: 'Comment', upvotable_id: Comment.of_group(group))
    .or(where(upvotable_type: 'Post', upvotable_id: Post.of_group(group)))
  }

  after_create :send_message
  before_validation :set_issue

  def sender_of_message(message)
    user
  end

  def post
    upvotable.is_a?(Post) ? upvotable : upvotable.post
  end

  def sticky_comment_for_message
    upvotable.is_a?(Comment) ? upvotable : nil
  end

  def post_for_message
    post
  end

  def issue_for_message
    issue
  end

  def group_for_message
    self.issue.group
  end

  def self.of_group_for_message(group)
    self.of_group(group)
  end

  private

  def send_message
    SendMessage.run(source: self, sender: self.user, action: :upvote)
  end

  def set_issue
    self.issue = upvotable.issue
  end
end
