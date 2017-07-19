class Comment < ActiveRecord::Base
  include Grape::Entity::DSL
  entity do
    include ApiEntityHelper

    expose :id, :choice, :upvotes_count
    expose :body do |instance|
      view_helpers.comment_format(instance.body, {}, { wrapper_tag: 'p' })
    end
    expose :truncated_body do |instance|
      body = view_helpers.comment_format(instance.body, {}, { wrapper_tag: 'p' })
      result = view_helpers.smart_truncate_html(body, length: 100, ellipsis: "... <read-more></read-more>")
      (result == body ? nil : result)
    end
    expose :user, using: User::Entity
    expose :created_at, format_with: lambda { |dt| dt.iso8601 }
    with_options(if: lambda { |instance, options| options[:current_user].present? }) do
      expose :is_mentionable do |instance, options|
        instance.mentionable? options[:current_user]
      end
      expose :is_upvotable do |instance, options|
        instance.upvotable? options[:current_user]
      end
      expose :is_upvoted_by_me do |instance, options|
        instance.upvoted_by? options[:current_user]
      end
      expose :is_destroyable do |instance, options|
        instance.user == options[:current_user]
      end
      expose :is_blinded do |instance, options|
        instance.blinded? options[:current_user]
      end
    end
  end

  acts_as_paranoid

  include Choosable
  include Mentionable
  include Upvotable
  mentionable :body

  belongs_to :user
  belongs_to :post, counter_cache: true
  has_one :issue, through: :post
  has_many :messages, as: :messagable, dependent: :destroy
  has_many :mentions, as: :mentionable, dependent: :destroy

  validates :user, presence: true
  validates :post, presence: true
  validates :body, presence: true

  scope :recent, -> { order(created_at: :desc).order(id: :desc) }
  scope :sequential, -> { order(created_at: :asc) }
  scope :next_of, ->(id) { where('comments.created_at > ?', with_deleted.find_by(id: id).try(:created_at)) if id.present? }
  scope :latest, -> { after(1.day.ago) }
  scope :persisted, -> { where "id IS NOT NULL" }
  scope :by_issue, ->(issue) { joins(:post).where(posts: {issue_id: issue})}
  scope :previous_of, ->(id) {
    if id.present?
      where('comments.created_at <= ?', with_deleted.find(id).created_at).where('comments.id < ?', id)
    end
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

  private

  def touch_last_commented_at_of_posts
    self.post.touch(:last_commented_at)
  end

  def touch_last_stroked_at_of_posts
    self.post.strok_by!(self.user, :comment)
  end

  def touch_last_stroked_at_of_issues
    self.issue.strok_by!(self.user, self.post)
  end

end
