class Issue < ActiveRecord::Base
  include Grape::Entity::DSL
  entity :id, :title, :body, :slug, :group, :updated_at do
    expose :logo, as: :logo_url do |instance|
      instance.logo.sm.url
    end
    expose :latest_members_count do |instance|
      instance.members.latest.count
    end
    expose :latest_posts_count do |instance|
      instance.posts.latest.count
    end
    expose :members_count do |instance|
      instance.members.count
    end
    expose :posts_count do |instance|
      instance.posts.count
    end

    with_options(if: lambda { |instance, options| !!options[:current_user] }) do
      expose :is_member do |instance, options|
        instance.member_by? options[:current_user] or instance.member? options[:current_user]
      end
      expose :is_made_by do |instance, options|
        instance.made_by? options[:current_user]
      end
    end
  end

  include UniqueSoftDeletable
  acts_as_unique_paranoid
  acts_as_taggable

  ALL_PARTI_NAME = '전체'
  TITLE_OF_PARTI_PARTI = '빠띠'
  SLUG_OF_PARTI_PARTI = 'parti'

  # relations
  has_many :relateds, dependent: :destroy
  has_many :related_issues, through: :relateds, source: :target
  has_many :posts, dependent: :destroy
  has_many :comments, through: :posts
  has_many :talks, through: :posts, source: :postable, source_type: Talk
  has_many :notes, through: :posts, source: :postable, source_type: Note
  # 이슈는 위키를 하나 가지고 있어요.
  has_one :wiki, dependent: :destroy
  has_many :makers, dependent: :destroy do
    def merge_nickname
      self.map { |m| m.user.nickname }.join(',')
    end
  end
  has_many :blinds, dependent: :destroy do
    def merge_nickname
      self.map { |m| m.user.nickname }.join(',')
    end
  end
  has_many :members, dependent: :destroy
  has_many :member_users, through: :members, source: :user
  has_many :sections, dependent: :destroy do
    def initial_section
      find_by(initial: true)
    end
  end

  # validations
  validates :title,
    presence: true,
    length: { maximum: 60 },
    uniqueness: { case_sensitive: false, scope: :group_slug }
  validates :body,
    length: { maximum: 200 }, on: :create
  VALID_SLUG = /\A[a-z0-9_-]+\z/i
  validates :slug,
    presence: true,
    format: { with: VALID_SLUG },
    exclusion: { in: %w(app new edit index session login logout users admin
    stylesheets assets javascripts images) },
    uniqueness: { case_sensitive: false, scope: :group_slug },
    length: { maximum: 100 }

  # fields
  mount_uploader :logo, ImageUploader
  attr_accessor :makers_nickname
  attr_accessor :blinds_nickname

  # callbacks
  before_save :downcase_slug
  before_create :build_wiki
  before_validation :strip_whitespace

  # scopes
  scope :hottest, -> { order('issues.member_count + issues.posts_count desc') }
  scope :recent, -> { order(created_at: :desc) }
  scope :recent_touched, -> { order(last_touched_at: :desc) }
  scope :only_group_or_all_if_blank, ->(group) { where(group_slug: group.slug) if group.present? }
  scope :categorized_with, ->(slug) { where(category_slug: slug) }
  scope :only_group, ->(group) { where(group_slug: (group.present? ? group.slug : nil)) }
  # search
  scoped_search on: [:title, :body]

  # methods

  def member_by? someone
    members.exists? user: someone
  end

  def member_email? email
    members.joins(:user).exists? 'users.email': email
  end

  def made_by? someone
    makers.exists? user: someone
  end

  def member? someone
    members.exists? user: someone
  end

  def is_all?
    false
  end

  def to_group(group)
    group_slug = group.slug
    members.each do |member|
      members.build(user: member.user) unless member?(member.user)
    end
  end

  def slug_formated_title
    return if self.title.blank?
    self.slug = self.title.strip.downcase.gsub(/\s+/, "-")
  end

  def related_with? something
    relateds.exists?(target: something)
  end

  def past_week?
    created_at > 1.week.ago
  end

  def recommends
    recommends = (Issue.past_week + Issue.hottest.limit(10)).uniq.shuffle.first(10)
    (related_issues + recommends - [self]).uniq.shuffle.first(10)
  end

  def self.basic_issues
    Issue.where basic: true
  end

  def counts_container
    counts = OpenStruct.new
    counts.comments_count = comments.count
    counts.latest_comments_count = comments.latest.count
    counts.talks_count = talks.count
    counts.latest_talks_count = talks.latest.count
    counts.notes_count = notes.count
    counts.latest_notes_count = notes.latest.count
    counts
  end

  def hottest_posts(count)
    posts.hottest.limit(count)
  end

  def compare_title(other)
    self_title = title.strip
    other_title = other.title.strip
    self_title.split('').each_with_index do |char, i|
      return -1 if other_title[i] == nil
      if self_title[i] != other_title[i]
        if (self_title[i].ascii_only? and other_title[i].ascii_only?) or (!self_title[i].ascii_only? and !other_title[i].ascii_only?)
          return self_title[i] <=> other_title[i]
        else
          return (self_title[i].ascii_only? ? 1 : -1)
        end
      end
    end
    self_title <=> other_title
  end

  def group
    Group.find_by_slug group_slug
  end

  def on_group?
    group_slug.present?
  end

  def postable? someone
    !on_group? or member?(someone)
  end

  def blind_user? someone
    blinds.exists?(user: someone) or Blind.site_wide?(someone)
  end

  def initial_section
    sections.find_by(initial: true)
  end

  def sender_of_message(message)
    message.user
  end

  def self.of_slug(slug, group_slug)
    self.find_by(slug: slug, group_slug: group_slug)
  end

  def self.most_used_tags(limit)
    ActsAsTaggableOn::Tag.where('taggings.taggable_type': 'Issue').most_used(limit).joins(:taggings).select('name').distinct
  end

  private

  def downcase_slug
    return if slug.blank?
    self.slug = slug.downcase
  end

  def strip_whitespace
    self.title = self.title.strip unless self.title.nil?
    self.slug = self.slug.strip unless self.slug.nil?
  end
end
