class Issue < ActiveRecord::Base
  acts_as_paranoid
  TITLE_OF_ASK_PARTI = 'Ask Parti'
  SLUG_OF_ASK_PARTI = 'ask-parti'
  OF_ALL = Naught.build do |config|
    config.singleton
    config.impersonate Issue
    def is_all?
      true
    end
    def title
      '모두보기'
    end
    def body
      '유쾌한 민주주의 플랫폼입니다! 중요한 이슈, 이제 빠띠로 지켜보세요.'
    end
    def slug
      'all'
    end
    def posts
      Post.all
    end
    def articles
      Article.all
    end
    def talks
      Talk.all
    end
    def opinions
      Opinion.all
    end
    def recommends
      (Issue.past_week + Issue.hottest.limit(10)).uniq.shuffle
    end
    def comments
      Comment.all
    end
    def watches
      User.all
    end
  end.instance

  def OF_ALL.logo_url
    ActionController::Base.helpers.asset_path('all_issue_logo.png')
  end
  def OF_ALL.cover_url
    ActionController::Base.helpers.asset_path('default_issue_cover.png')
  end

  # relations
  has_many :relateds
  has_many :related_issues, through: :relateds, source: :target
  has_many :posts, dependent: :destroy
  has_many :comments, through: :posts
  has_many :articles, through: :posts, source: :postable, source_type: Article
  has_many :opinions, through: :posts, source: :postable, source_type: Opinion
  has_many :talks, through: :posts, source: :postable, source_type: Talk
  has_many :watches do
    def latest
      after(1.day.ago)
    end
  end

  # validations
  validates :title, presence: true, uniqueness: { case_sensitive: false }
  VALID_SLUG = /\A[a-z0-9_-]+\z/i
  validates :slug,
    presence: true,
    format: { with: VALID_SLUG },
    exclusion: { in: %w(app new edit index session login logout users admin
    stylesheets assets javascripts images) },
    uniqueness: { case_sensitive: false },
    length: { maximum: 100 }

  # fields
  mount_uploader :logo, ImageUploader
  mount_uploader :cover, ImageUploader

  # callbacks
  before_save :downcase_slug

  # scopes
  scope :hottest, -> { order('issues.watches_count + issues.posts_count desc') }

  # methods
  def watched_by? someone
    watches.exists? user: someone
  end

  def is_all?
    false
  end

  def slug_formated_title
    return if self.title.blank?
    self.slug = self.title.strip.downcase.gsub(/\s+/, "-")
  end

  # deprecated
  def contributors
    commiters
  end

  def commiters
    (posts.map(&:user) + watches.map(&:user)).compact.uniq
  end

  def related_with? something
    relateds.exists?(target: something)
  end

  def past_week?
    created_at > 1.week.ago
  end

  def recommends
    (related_issues + OF_ALL.recommends - [self]).uniq.shuffle
  end

  def recommends_for_watch(someone)
    Issue.hottest.where.not(id: someone.watched_issues).limit(10)
  end

  def self.featured_issues(someone)
    result = []
    result << someone.watched_issues if someone.present?
    result << parti_issues
    result.flatten.compact.uniq.sort_by { |i| [i.title] }
  end

  def self.parti_issues
    Issue.where slug: %w(basic-income sewolho 20th-general-election)
  end

  def counts_container
    counts = OpenStruct.new
    counts.articles_count = articles.count
    counts.latest_articles_count = articles.latest.count
    counts.comments_count = posts.sum(:comments_count)
    counts.latest_comments_count = posts.latest.sum(:comments_count)
    counts.opinions_count = opinions.count
    counts.latest_opinions_count = opinions.latest.count
    counts.talks_count = talks.count
    counts.latest_talks_count = talks.latest.count
    counts
  end

  private

  def downcase_slug
    return if slug.blank?
    self.slug = slug.downcase
  end
end
