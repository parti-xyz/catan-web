class Comment < ActiveRecord::Base
  include Grape::Entity::DSL
  entity do
    expose :id, :choice, :upvotes_count
    expose :body do |instance|
      ActionView::Base.send(:include, Rails.application.routes.url_helpers)
      ApplicationController.helpers.comment_format(instance.body, {}, {as_url: true})
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

  scope :recent, -> { order(created_at: :desc) }
  scope :sequential, -> { order(created_at: :asc) }
  scope :next_of, ->(id) { where('comments.created_at > ?', with_deleted.find_by(id: id).try(:created_at)) if id.present? }
  scope :latest, -> { after(1.day.ago) }
  scope :persisted, -> { where "id IS NOT NULL" }
  scope :by_issue, ->(issue) { joins(:post).where(posts: {issue_id: issue})}
  scope :previous_of, ->(id) { where('comments.created_at < ?', with_deleted.find(id).created_at) if id.present? }

  after_create :send_messages
  after_create :touch_last_commented_at_of_posts
  after_create :touch_last_touched_at_of_posts
  after_create :touch_last_touched_at_of_issues

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
    !upvotes.exists?(user: someone)
  end

  def issue_for_message
    self.issue
  end

  private

  def send_messages
    MessageService.new(self).call
  end

  def touch_last_commented_at_of_posts
    self.post.touch(:last_commented_at)
  end

  def touch_last_touched_at_of_posts
    self.post.touch(:last_touched_at)
  end

  def touch_last_touched_at_of_issues
    self.issue.touch(:last_touched_at)
  end

end
