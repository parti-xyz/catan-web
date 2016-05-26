class Campaign < ActiveRecord::Base
  include Watchable
  include UniqueSoftDeletable
  acts_as_unique_paranoid

  # relations
  belongs_to :user
  has_many :issues, dependent: :nullify
  has_many :posts, through: :issues
  has_many :comments, through: :posts
  has_many :campaigned_issues
  has_many :issues, through: :campaigned_issues

  # validations
  validates :title, presence: true, uniqueness: { case_sensitive: false }
  VALID_SLUG = /\A[a-z0-9_-]+\z/i
  validates :slug,
    presence: true,
    format: { with: VALID_SLUG },
    exclusion: { in: %w(all campaign app new edit index session login logout users admin
    stylesheets assets javascripts images) },
    uniqueness: { case_sensitive: false },
    length: { maximum: 100 }

  # fields
  mount_uploader :logo, ImageUploader
  mount_uploader :cover, ImageUploader
  attr_accessor :issue_slugs

  # callbacks
  before_save :downcase_slug

  # methods
  def watched_by? someone
    watches.exists? user: someone
  end

  def best_articles
    Post.best_articles_in_issues(issues, 4).map(&:specific)
  end

  def best_opinions
    Post.best_opinions_in_issues(issues, 4).map(&:specific)
  end

  def best_talks
    Post.best_talks_in_issues(issues, 4).map(&:specific)
  end

  private

  def downcase_slug
    return if slug.blank?
    self.slug = slug.downcase
  end
end
