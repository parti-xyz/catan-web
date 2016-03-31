class Post < ActiveRecord::Base
  HOT_LIKES_COUNT = 3

  acts_as_paranoid
  acts_as_taggable
  actable as: :postable
  paginates_per 20

  belongs_to :issue, counter_cache: true
  belongs_to :user
  has_many :comments, dependent: :destroy do
    def users
      self.map(&:user).uniq
    end
  end
  has_many :votes, dependent: :destroy do
    def users
      self.map(&:user).uniq
    end

    def partial_included_with(someone)
      partial = recent.limit(100)
      if !partial.map(&:user).include?(someone)
        (partial.all << find_by(user: someone)).compact
      else
        partial.all
      end
    end

    def point
      agreed.count - disagreed.count
    end
  end
  has_many :likes, counter_cache: true
  has_many :like_users, through: :likes, source: :user

  # validations
  validates :issue, presence: true
  validates :user, presence: true

  # scopes
  default_scope -> { joins(:issue) }
  scope :recent, -> { order(created_at: :desc) }
  scope :hottest, -> {
    select('posts.*, COUNT(likes.id) likes_count')
      .joins(:likes)
      .group('posts.id')
      .past_week(field: 'likes.created_at')
      .reorder('likes_count DESC').recent }
  scope :yesterday_hottest, -> {
    select('posts.*, COUNT(likes.id) likes_count')
      .joins(:likes)
      .group('posts.id')
      .yesterday(field: 'likes.created_at')
      .having("likes_count > #{HOT_LIKES_COUNT}")
      .reorder('likes_count DESC').recent }
  scope :watched_by, ->(someone) { where(issue_id: someone.watched_issues) }
  scope :by_postable_type, ->(t) { where(postable_type: t.camelize) }
  scope :by_filter, ->(f, someone=nil) {
    case f.to_sym
    when :hottest
      hottest
    when :best
      reorder(likes_count: :desc).recent
    when :like
      only_like_by(someone).recent
    when :recent
      recent
    end
  }
  scope :only_articles, -> { by_postable_type(Article.to_s) }
  scope :only_opinions, -> { by_postable_type(Opinion.to_s) }
  scope :only_talks, -> { by_postable_type(Talk.to_s) }
  scope :only_like_by, ->(someone) { joins(:likes).where('likes.user': someone) }
  scope :latest, -> { after(1.day.ago) }

  ## uploaders
  # mount
  mount_uploader :social_card, ImageUploader

  def liked_by? someone
    likes.exists? user: someone
  end

  def voted_by voter
    votes.where(user: voter).first
  end

  def voted_by? voter
    votes.exists? user: voter
  end

  def agreed_by? voter
    votes.exists? user: voter, choice: 'agree'
  end

  def disagreed_by? voter
    votes.exists? user: voter, choice: 'disagree'
  end

  def hot?
    likes.past_week.count > HOT_LIKES_COUNT
  end

  def specific_desc
    specific.try(:title) || specific.try(:body)
  end

  def origin
    specific.origin.post
  end

  def linkable?
    specific.is_a? Article
  end

  def messablable_users
    (comments.users + votes.users).uniq
  end

  def self.recommends(exclude)
    result = recent.limit(10)
    if result.length < 10
      result += recent.limit(10)
      result = result.uniq
    end
    result - [exclude]
  end

  def self.hottest_count
    hottest.length
  end
end
