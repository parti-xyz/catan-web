class Issue < ApplicationRecord
  include Grape::Entity::DSL
  entity do
    expose :id, :title, :slug
    expose :category_id, as: :categoryId
    expose :logoUrl do |instance, options|
      instance.logo.lg.url
    end
    expose :groupId do |instance, _|
      instance.group.id
    end
    expose :isMember do |instance, _|
      instance.member?(options[:current_user])
    end
  end

  include LatestStrokedPostsCountHelper

  include UniqueSoftDeletable
  acts_as_unique_paranoid
  acts_as_taggable

  SLUG_OF_PARTI_PARTI = 'parti'

  include Invitable
  # relations
  belongs_to :last_stroked_user, class_name: "User", optional: true
  has_many :merged_issues, dependent: :destroy
  has_many :relateds, dependent: :destroy
  has_many :related_issues, through: :relateds, source: :target
  has_many :relatings, class_name: "Related", foreign_key: :target_id, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :comments, through: :posts
  #**
  #** 중요 : 아래 members를 이용하지 말고 MemberIssueService를 이용하여 가입처리를 해야합니다
  #**
  has_many :members, as: :joinable, dependent: :destroy
  has_many :member_users, through: :members, source: :user
  has_many :organizer_members, -> { where(is_organizer: true) }, as: :joinable, class_name: "Member" do
    def merge_nickname
      self.map { |m| m.user.nickname }.join(',')
    end
  end
  has_many :blinds, dependent: :destroy do
    def merge_nickname
      self.map { |m| m.user.nickname }.join(',')
    end
  end
  has_many :member_requests, as: :joinable, dependent: :destroy
  has_many :member_request_users, through: :member_requests, source: :user
  has_many :blind_users, through: :blinds, source: :user
  has_many :messages, as: :messagable, dependent: :destroy
  has_many :invitations, as: :joinable, dependent: :destroy
  belongs_to :destroyer, class_name: "User", optional: true
  belongs_to :group, foreign_key: :group_slug, primary_key: :slug, counter_cache: true
  has_many :active_issue_stats, dependent: :destroy
  has_many :folders, dependent: :destroy
  belongs_to :category, optional: true
  has_many :issue_post_formats, dependent: :destroy, class_name: 'GroupHomeComponentPreference::IssuePostsFormat'
  belongs_to :blinded_by, class_name: "User", foreign_key: 'blinded_by_id', optional: true

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
    exclusion: { in: %w(all app new edit index session login logout users admin
    stylesheets assets javascripts images) },
    uniqueness: { case_sensitive: false, scope: :group_slug },
    length: { maximum: 100 }
  validate :not_parti_parti_slug

  # fields
  mount_uploader :logo, ImageUploader
  attr_accessor :organizer_nicknames
  attr_accessor :blinds_nickname

  # callbacks
  before_save :downcase_slug
  before_validation :strip_whitespace

  # scopes
  scope :never_blinded, -> { where(blinded_at: nil) }
  scope :blinded_only, -> { where.not(blinded_at: nil) }
  scope :alive, -> { where(freezed_at: nil) }
  scope :dead, -> { where.not(freezed_at: nil) }
  scope :only_public_in_current_group, ->(current_group = nil) {
    result = where.not(private: true).alive
    if current_group.blank?
      result = result.joins(:group).where.not('groups.private': true)
    end
    result
  }
  scope :sort_by_name, -> { order(Arel.sql("if(ascii(substring(issues.title, 1)) < 128, 1, 0)")).order('issues.title') }
  scope :hottest, -> { order(hot_score_datestamp: :desc, hot_score: :desc) }
  scope :this_week_or_hottest, -> { order(Arel.sql("if(issues.created_at < (NOW() - INTERVAL 6 DAY), 1, 0)")).order(hot_score_datestamp: :desc, hot_score: :desc) }
  scope :recent, -> { order(created_at: :desc) }
  scope :recent_touched, -> { order(last_stroked_at: :desc) }
  scope :categorized_with, ->(category) { where(category_id: category.try(:id) || category) }
  scope :of_group, ->(group) { where(group_slug: Group.slug_fallback(group)) }
  scope :only_alive_of_group, ->(group) { alive.where(group_slug: Group.slug_fallback(group)) }
  scope :displayable_in_current_group, ->(group) { never_blinded.where(group_slug: Group.slug_fallback(group)) if group.present? }
  scope :not_private_blocked, ->(current_user) {
    never_blinded.where(id: Member.where(user: current_user).where(joinable_type: 'Issue').select('members.joinable_id'))
    .or(where.not(private: true))
  }
  scope :not_in_dashboard, ->(current_user) { where.not(id: Member.where(user: current_user).where(joinable_type: 'Issue').select('members.joinable_id'))
                                             .where.not('issues.private': true) }
  scope :notice_only, -> { where(notice_only: true) }
  scope :only_public_hottest, ->(count){
    where(group_slug: Group.only_public.select(:slug))
    .alive.never_blinded
    .where.not(private: true)
    .hottest
    .limit(count)
  }
  scope :searchable_issues, ->(current_user = nil) {
    public_group_public_issues = never_blinded.where(group_slug: Group.only_public.select(:slug))
      .where.not(private: true).or(where(listable_even_private: true))
    if current_user.present?
      public_group_public_issues
        .or(where(id: current_user.member_issues.select("members.joinable_id")))
    else
      public_group_public_issues
    end
  }
  scope :post_searchable_issues, ->(current_user = nil) {
    public_group_public_issues = never_blinded.where(group_slug: Group.only_public.select(:slug)).where.not(private: true)
    if current_user.present?
      public_group_public_issues
        .or(where(id: current_user.member_issues.select("members.joinable_id")))
    else
      public_group_public_issues
    end
  }
  scope :undiscovered_issues, ->(current_user = nil) {
    public_group_public_issues = never_blinded.where(group_slug: Group.only_public.select(:slug)).where.not(private: true)
    conditions = public_group_public_issues
    if current_user.present?
      conditions = conditions.where.not(id: current_user.member_issues.select("members.joinable_id"))
    end
    conditions
  }
  scope :not_joined_issues, ->(current_user) {
    where.not(id: Member.for_issues.where(user: current_user).select("members.joinable_id")) if current_user.present?
  }
  scope :joined_issues, ->(current_user) {
    where(id: Member.for_issues.where(user: current_user).select("members.joinable_id")) if current_user.present?
  }
  scope :only_private, -> { where(private: true) }
  scope :not_private, -> { where(private: false) }
  scope :postable, ->(someone) {
    if someone.present?
      where(id: someone.organizing_issues).or(where(id: someone.member_issues, notice_only: false))
    else
      where(id: nil)
    end
  }

  # search
  scoped_search on: [:title, :body]

  # methods

  def member_email? email
    members.joins(:user).exists? 'users.email': email
  end

  def organized_by? someone
    return false if someone.blank?
    cached_member = someone.cached_parti_member(self)
    return cached_member.is_organizer if cached_member.present?

    organizer_members.exists? user: someone
  end

  def member? someone
    return false if someone.blank?
    cached_member = someone.cached_parti_member(self)
    return cached_member if cached_member.present?

    members.exists? user: someone
  end

  def member_requested? someone
    member_requests.exists? user: someone
  end

  def change_group(group)
    self.group_slug = group.slug
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

  def counts_container
    counts = OpenStruct.new
    counts.comments_count = comments.count
    counts.latest_comments_count = comments.latest.count
    counts.posts_count = posts.count
    counts.latest_posts_count = posts.latest.count
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

  def group_subdomain
    group.subdomain
  end

  def postable? someone
    return false if blind_user?(someone)
    return false if private_blocked?(someone)
    return true if organized_by?(someone)
    member?(someone) and !notice_only
  end

  def blind_user? someone
    blinds.exists?(user: someone) or Blind.site_wide?(someone)
  end

  def sender_of_message(message)
    message.user
  end

  def share_image_dimensions
    [300, 158]
  end

  def share_image_url
    logo.md.url
  end

  def self.of_slug(slug, group_slug = nil)
    self.find_by(slug: slug, group_slug: Group.slug_fallback(group_slug))
  end

  def self.most_used_tags(limit)
    ActsAsTaggableOn::Tag.most_used(limit).joins(:taggings).where('taggings.taggable_type = ?', 'Issue').distinct
  end

  def self.parti_parti
    find_by(slug: Issue::SLUG_OF_PARTI_PARTI, group_slug: Group::SLUG_OF_UNION)
  end

  def issue_for_message
    self
  end

  def group_for_message
    self.group
  end

  def private_blocked?(someone = nil)
    (!member?(someone) && private?) or (self.group.private_blocked?(someone))
  end

  def host_group?(host_group)
    host_group&.slug == self.group_slug
  end

  def fallbackable_organizer_member_users
    organizer_members.present? ? organizer_members.to_a.map(&:user) : [User.find_by(nickname: 'parti')]
  end

  def strok_by(someone)
    self.last_stroked_at = DateTime.now
    self.last_stroked_user = someone
    self
  end

  def strok_by!(someone, post)
    return if post.blinded?

    update_columns(last_stroked_at: DateTime.now, last_stroked_user_id: someone.id)
  end

  def members_with_deleted
    Member.with_deleted.where(joinable: self)
  end

  def member_requests_with_deleted
    MemberRequest.with_deleted.where(joinable: self)
  end

  def frozen?
    freezed_at.present?
  end

  def alive?
    ! frozen?
  end

  def comments_count
    posts.sum(:comments_count)
  end

  def not_blind_hottest_posts(count, current_user)
    posts.hottest.limit(count).reject { |post| post.blinded?(current_user) }
  end

  def not_blind_recent_posts(count, current_user)
    posts.recent.limit(count).reject { |post| post.blinded?(current_user) }
  end

  def default_image_pick_up
    %w(green yellow blue)[self.id % 3]
  end

  def active_wiki_count
    Wiki.where(id: posts.select(:wiki_id)).with_status(:active).count
  end

  def inactive_wiki_count
    Wiki.where(id: posts.select(:wiki_id)).with_status(:inactive).count
  end

  def exists_wiki?
    posts.exists?(['wiki_id is not ?', nil])
  end

  def movable_to_group? target_group
    member_users.each do |user|
      return false if !target_group.member?(user)
    end
    true
  end

  def visiable_latest_stroked_posts_count
    (LatestStrokedPostsCountHelper.current_version == latest_stroked_posts_count_version ? latest_stroked_posts_count : 0)
  end

  def member_of someone
    members.find_by(user: someone)
  end

  def experimental?
    group_slug == 'union' and %(xyz).include?(slug)
  end

  def rookie?
    created_at > 1.weeks.ago
  end

  def compact_messagable_users
    self.member_users.where(id: IssuePushNotificationPreference.where(issue: self).compact_messagables.select(:user_id))
  end

  def detail_messagable_users
    self.member_users.where(id: IssuePushNotificationPreference.where(issue: self).detail_messagables.select(:user_id))
  end

  def self.messagable_group_method
    :of_group
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

  def not_parti_parti_slug
    if self.slug == Issue::SLUG_OF_PARTI_PARTI and self.group_slug != Group::SLUG_OF_UNION
      errors.add(:slug, I18n.t('errors.messages.taken'))
    end
  end
end
