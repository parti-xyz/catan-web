class Comment < ApplicationRecord
  acts_as_paranoid

  include Choosable
  include Mentionable
  include Upvotable
  mentionable :body

  belongs_to :parent, class_name: "Comment", foreign_key: :parent_id, optional: true
  has_many :children, class_name: "Comment", foreign_key: :parent_id, dependent: :destroy

  belongs_to :user
  belongs_to :post, counter_cache: true
  has_one :issue, through: :post
  has_many :messages, as: :messagable, dependent: :destroy
  has_many :mentions, as: :mentionable, dependent: :destroy
  has_many :file_sources, dependent: :destroy, as: :file_sourceable
  accepts_nested_attributes_for :file_sources, allow_destroy: true, reject_if: proc { |attributes|
    attributes['attachment'].blank? and attributes['attachment_cache'].blank? and attributes['id'].blank?
  }
  has_many :comment_readers, dependent: :destroy

  validates :user, presence: true
  validates :post, presence: true
  validates :body, presence: true

  scope :recent, -> { order(created_at: :desc).order(id: :desc) }
  scope :sequential, -> { order(created_at: :asc) }
  scope :next_of, ->(id) {
    if id.present?
      where('comments.created_at > ?', with_deleted.find_by(id: id).try(:created_at))
    end
  }
  scope :latest, -> { after(1.day.ago) }
  scope :persisted, -> { where "id IS NOT NULL" }
  scope :by_issue, ->(issue) { joins(:post).where(posts: {issue_id: issue})}
  scope :previous_of, ->(id) {
    if id.present?
      where('comments.created_at <= ?', with_deleted.find(id).created_at).where('comments.id < ?', id)
    end
  }
  scope :only_parent, -> { where(parent: nil) }
  scope :of_group, -> (group) { where(post_id: Post.of_group(group)) }
  scope :unread, -> (someone) {
    where('id >= ?', CommentReader::BEGIN_COMMENT_ID)
    .where.not(user: someone)
    .where.not('created_at < ?', CommentReader::VALID_PERIOD)
    .where.not(id: CommentReader.where(user_id: someone.try(:id) || 0).select(:comment_id))
  }

  after_create :touch_last_commented_at_of_posts
  after_create :touch_last_stroked_at_of_posts
  after_create :touch_last_stroked_at_of_issues

  def mentioned? someone
    mentions.exists? user: someone
  end

  def blinded? someone
    return false if someone == self.user
    issue.blind_user? self.user
  end

  def mentionable? someone
    return false if someone.blank?
    return false if someone == self.user
    return true
  end

  def sender_of_message(message)
    user
  end

  def upvotable? someone
    return false if someone.blank?
    !upvoted_by?(someone)
  end

  def sticky_comment_for_message
    self
  end

  def post_for_message
    post
  end

  def issue_for_message
    self.issue
  end

  def group_for_message
    self.issue.group
  end

  def body_html?
    false
  end

  def private_blocked?(someone = nil)
    post.private_blocked? someone
  end

  def parent_or_self
    parent || self
  end

  def self.setup_threads(comments)
    result = comments.to_a.group_by { |comment| comment.parent_or_self }.to_a.sort_by { |item| item[0].created_at }
    result.each do |item|
      parent_comment = item[0]
      child_comments = item[1]

      child_comments.reject! { |comment| comment.parent.blank? }
      child_comments.sort_by! { |comment| comment.created_at }

      if child_comments.first.present?
        child_comments = [child_comments.first]
        child_comments += parent_comment.children.next_of(child_comments.first.id).order(:created_at).to_a
      end

      if (parent_comment.children.count - child_comments.length) == 1
        child_comments = parent_comment.children.order(:created_at).to_a
      end

      item[0] = parent_comment
      item[1] = child_comments
    end
    result
  end

  def self.messagable_group_method
    :of_group
  end

  def read!(someone)
    return if someone.blank?
    return if self.user == someone
    return if self.created_at < CommentReader::VALID_PERIOD.ago
    self.comment_readers.find_or_create_by(user: someone)
  end

  def read?(someone)
    return true if someone.blank?
    return true if self.user == someone
    return true if self.created_at < CommentReader::VALID_PERIOD.ago
    return true if self.id < CommentReader::BEGIN_COMMENT_ID
    self.comment_readers.exists?(user: someone)
  end

  def almost_deleted?
    self.almost_deleted_at.present?
  end

  def self.users(comments, limit)
    User.where(id: comments.select(:user_id).distinct).limit(limit)
  end

  private

  def touch_last_commented_at_of_posts
    self.post.touch(:last_commented_at)
  end

  def touch_last_stroked_at_of_posts
    self.post.strok_by!(self.user, :comment)
  end

  def touch_last_stroked_at_of_issues
    self.issue.strok_by!(self.user, self.post)
    self.issue.visit_if_no_unread_posts!(self.user)
  end

end
