class Post < ActiveRecord::Base
  HOT_LIKES_COUNT = 3

  include Upvotable

  acts_as_paranoid
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

  # validations
  validates :issue, presence: true
  validates :user, presence: true

  # scopes
  default_scope -> { joins(:issue) }
  scope :recent, -> { order(created_at: :desc) }
  scope :hottest, -> { order(latest_comments_counted_datestamp: :desc, latest_comments_count: :desc) }
  scope :watched_by, ->(someone) { where(issue_id: someone.watched_issues) }
  scope :by_postable_type, ->(t) { where(postable_type: t.camelize) }
  scope :only_articles, -> { by_postable_type(Article.to_s) }
  scope :only_opinions, -> { by_postable_type(Opinion.to_s) }
  scope :only_talks, -> { by_postable_type(Talk.to_s) }
  scope :latest, -> { after(1.day.ago) }
  scope :previous_of, ->(id) { where('posts.last_commented_at < ?', with_deleted.find(id).last_commented_at) if id.present? }
  scope :previous_of_post, ->(post) { where('posts.last_commented_at < ?', post.last_commented_at) if post.present? }
  scope :next_of_post, ->(post) { where('posts.last_commented_at >= ?', post.last_commented_at) if post.present? }

  ## uploaders
  # mount
  mount_uploader :social_card, ImageUploader

  # callbacks
  before_create :touch_last_touched_at

  def vote_by voter
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

  def sured_by? voter
    votes.exists? user: voter, choice: ['agree', 'disagree']
  end

  def unsured_by? voter
    votes.exists? user: voter, choice: 'unsure'
  end

  def specific_desc
    specific.try(:title) || specific.try(:body)
  end

  def origin
    specific.specific_origin.post
  end

  def linkable?
    specific.is_a? Article
  end

  def messagable_users
    (comments.users + votes.users).uniq
  end

  def latest_comments
    comments.recent.limit(2).reverse
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

  def self.best_articles_in_issues(issues, count)
    self.where(issue: issues).only_articles.hottest.limit(count)
  end

  def self.best_opinions_in_issues(issues, count)
    self.where(issue: issues).only_opinions.hottest.limit(count)
  end

  def self.best_talks_in_issues(issues, count)
    self.where(issue: issues).only_talks.hottest.limit(count)
  end

  private

  def touch_last_touched_at
    self.last_touched_at = DateTime.now
  end
end
