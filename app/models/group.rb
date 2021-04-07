class Group < ApplicationRecord
  include Grape::Entity::DSL
  entity do
    expose :id, :title, :slug
    expose :categories, using: Category.entity do |instance, options|
      instance.categories.sort_by_name
    end
    expose :logoUrl do |instance, options|
      instance.logo.lg.url
    end
    expose :issues, using: Issue.entity, as: :channels do |instance, options|
      current_user = options[:current_user]
      result = instance.issues.recent_touched.reject do |issue|
        issue.private_blocked?(current_user) and !current_user.try(:admin?) and !issue.listable_even_private?
      end
    end
    expose :isMember do |instance, _|
      instance.member?(options[:current_user])
    end
  end

  attr_accessor :organizer_nicknames

  include UniqueSoftDeletable
  acts_as_unique_paranoid

  include Invitable

  extend Enumerize
  enumerize :plan, in: [:premium, :lite, :trial], predicates: true, scope: true
  enumerize :issue_creation_privileges, in: [:member, :organizer], predicates: true, scope: true
  SLUG_OF_UNION = 'union'
  SLUG_OF_ACTIVIST = 'democracy-activists'
  DEFAULT_SLUG = 'open'

  belongs_to :user, optional: true
  has_many :invitations, as: :joinable, dependent: :destroy
  has_many :members, as: :joinable, dependent: :destroy
  has_many :organizer_members, -> { where(is_organizer: true) }, as: :joinable, class_name: "Member" do
    def merge_nickname
      self.map { |m| m.user.nickname }.join(',')
    end
  end
  has_many :member_users, through: :members, source: :user
  has_many :member_requests, as: :joinable, dependent: :destroy
  has_many :member_request_users, through: :member_requests, source: :user
  has_many :issues, dependent: :restrict_with_error, primary_key: :slug, foreign_key: :group_slug
  has_many :categories, dependent: :destroy, foreign_key: :group_slug, primary_key: :slug
  has_many :group_home_components, dependent: :destroy
  has_many :group_push_notification_preferences, dependent: :destroy
  belongs_to :main_wiki_post, class_name: 'Post', optional: true
  belongs_to :main_wiki_post_by, class_name: 'User', optional: true
  belongs_to :blinded_by, class_name: "User", foreign_key: 'blinded_by_id', optional: true
  has_many :last_visited_users, as: :last_visitable, class_name: 'User', dependent: :nullify
  has_many :labels, dependent: :destroy
  has_many :group_observation, dependent: :destroy, class_name: 'MessageConfiguration::GroupObservation'

  scope :sort_by_name, -> { order(Arel.sql("case when slug = '#{Group::DEFAULT_SLUG}' then 0 else 1 end")).order(Arel.sql("if(ascii(substring(title, 1)) < 128, 1, 0)")).order(:title) }
  scope :hottest, -> { order(Arel.sql("case when slug = '#{Group::DEFAULT_SLUG}' then 0 else 1 end")).order(hot_score_datestamp: :desc, hot_score: :desc) }
  scope :but, ->(group) { where.not(id: group) }
  scope :not_private_blocked, ->(current_user) {
    never_blinded.where(id: Member.where(user: current_user).where(joinable_type: 'Group').select('members.joinable_id'))
    .or(where.not(private: true))
  }
  scope :memberable_and_unfamiliar, ->(current_user) {
    never_blinded.where.not(id: Member.where(user: current_user).where(joinable_type: 'Group').select('members.joinable_id'))
    .where.not(private: true).where('issues_count > 0')
  }
  scope :only_public, -> { never_blinded.where.not(private: true) }
  scope :searchable_groups, ->(current_user = nil) {
    if current_user.present?
      only_public
        .or(where(id: current_user.member_groups))
    else
      only_public
    end
  }
  scope :sibilings, ->(group) {
    where(organization_slug: group.organization_slug)
  }

  mount_uploader :key_visual_foreground_image, ImageUploader
  mount_uploader :key_visual_background_image, ImageUploader
  mount_base64_uploader :logo, ImageUploader, file_name: -> (u) { 'userpic' }

  validates :title,
    presence: true,
    length: { maximum: 20 }
  validates :title,
    uniqueness: { case_sensitive: false },
    unless: :deleted?
  validates :site_description,
    length: { maximum: 200 }
  VALID_SLUG = /\A[a-z][a-z0-9-]+\z/i
  validates :slug,
    presence: true,
    format: { with: VALID_SLUG },
    exclusion: { in: %w(all app new edit index session login logout users admin stylesheets assets javascripts images dev dev2 test) },
    uniqueness: { case_sensitive: false },
    length: { maximum: 20 }
  validate :not_predefined_slug
  validates :head_title,
    uniqueness: { case_sensitive: false },
    length: { maximum: 10 }
  validates :site_title,
    length: { maximum: 50 }

  # callbacks
  before_save :downcase_slug
  before_validation :strip_whitespace

  # scopes
  scope :never_blinded, -> { where(blinded_at: nil) }
  scope :blinded_only, -> { where.not(blinded_at: nil) }
  scope :comprehensive_joined_by, -> (someone) {
    never_blinded.where(slug: (someone&.member_issues&.select(:group_slug)))
      .or(self.where(id: someone&.member_groups))
  }
  scope :joined_groups, -> (someone) {
    never_blinded.where(id: someone&.member_groups)
  }

  # search
  scoped_search on: [:title, :slug, :site_title, :head_title]

  def title_share_format
    "#{title} | #{I18n.t('labels.app_name_human')}"
  end

  def title_basic_format
    "#{title} 그룹"
  end

  def title_short_format
    title
  end

  def private_blocked?(someone = nil)
    !member?(someone) && private?
  end

  def organized_by? someone
    return false if someone.blank?
    cached_member = someone.cached_group_member(self)
    return cached_member.is_organizer if cached_member.present?

    organizer_members.exists? user: someone
  end

  def member? someone
    return false if someone.blank?
    cached_member = someone.cached_group_member(self)
    return true if cached_member.present?

    members.exists? user: someone
  end

  def member_of someone
    return nil if someone.blank?
    cached_member = someone.cached_group_member(self)
    cached_member.presence || self.members.find_by(user: someone)
  end

  def head_title
    (read_attribute(:head_title).presence || read_attribute(:title).presence || "").truncate(10)
  end

  def site_title
    read_attribute(:site_title).presence || read_attribute(:title)
  end

  def member_requested?(someone)
    return false if someone.blank?
    member_requests.exists? user: someone
  end

  def seo_image
    if File.exist?("app/assets/images/groups/#{self.slug}_seo.png")
      "groups/#{self.slug}_seo.png"
    else
      "parti_seo.png"
    end
  end

  def subdomain
    Group.subdomain(self.slug)
  end

  def self.subdomain(slug)
    slug
  end

  def open_square?
    self.slug == Group::DEFAULT_SLUG
  end

  def out_of_member_users member_users
    member_users.to_a.select { |user| !member?(user) }
  end

  def comprehensive_joined_by?(someone)
    return false if someone.blank?
    Group.comprehensive_joined_by(someone).exists?(id: self)
  end

  def default_issues
    issues.where(is_default: true)
  end

  def is_light_theme?
    false
  end

  def comprehensive_joined_users
    User.where(id: Member.where(joinable: self.issues).select(:user_id))
  end

  def self.find_by_slug(slug)
    find_by(slug: slug)
  end

  def self.exists_slug?(slug)
    exists? slug: slug
  end

  def self.slug_fallback(current_group)
    current_group.try(:slug) || (current_group if current_group.is_a?(String)) || Group::DEFAULT_SLUG
  end

  def self.open_square
    @__open_square ||= find_by(slug: 'open')
    @__open_square
  end

  def pinned_posts(someone)
    noticed_issues = self.issues.only_public.to_a
    if someone.present?
      noticed_issues += self.issues.where(id: someone.member_issues).to_a
      noticed_issues.uniq!
    end

    pinned_posts = noticed_issues.map do |issue|
      issue.posts.pinned.to_a
    end.flatten.compact
    pinned_posts.sort_by { |post| post.created_at }.reverse
  end

  def guide_link
    if 'zakdang' == slug
      "https://wouldyouparty.gitbooks.io/party_guide/"
    elsif %w(slowalk westay1 parti democracy-activists adaptiveleadership youthpolicynet).include? slug
      "https://parti-xyz.gitbooks.io/org-guide/content/"
    else
      "https://parti-xyz.gitbooks.io/issue-guide/content/"
    end
  end

  def members_with_deleted
    Member.with_deleted.where(joinable: self)
  end

  def member_requests_with_deleted
    MemberRequest.with_deleted.where(joinable: self)
  end

  ISSUE_QUOTA_FOR_LITE_PLAN = 10
  def quota_target_issues
    if private?
      issues
    else
      issues.only_private
    end
  end

  def met_issues_quota?
    return false unless has_issues_quota?
    quota_target_issues.count >= Group::ISSUE_QUOTA_FOR_LITE_PLAN
  end

  def will_violate_issues_quota?(working_issue)
    return false unless has_issues_quota?

    target_count = quota_target_issues.count

    if quota_target_issues.include?(working_issue)
      target_count -= 1
    end

    if private? or working_issue.private?
      target_count = target_count + 1
    end

    target_count > Group::ISSUE_QUOTA_FOR_LITE_PLAN
  end

  def trial?
    plan == :trial
  end

  def has_issues_quota?
    return false if open_square?
    plan == :lite
  end

  def changable_private_for_issue?(issue)
    return true unless has_issues_quota?
    return true if issue.private?
    return true if private?
    !met_issues_quota?
  end

  def visiable_latest_issues_count
    (LatestIssuesCountHelper.current_version == latest_issues_count_version ? latest_issues_count : 0)
  end

  def creatable_issue?(someone)
    return false if someone.blank?
    return true if someone.admin?
    return true if self.open_square?
    return self.member?(someone) if self.issue_creation_privileges.member?
    return self.organized_by?(someone) if self.issue_creation_privileges.organizer?
    false
  end

  def arrange_seq_group_home_components!
    ActiveRecord::Base.transaction do
      index = 0
      self.group_home_components.sequenced.each do |group_home_component|
        index += 1
        group_home_component.seq_no = index
        group_home_component.save!
      end
    end
  end

  def organization
    Organization.find_by_slug(self.organization_slug)
  end

  def group_for_message
    self
  end

  def group_for_invitation
    self
  end

  private

  def downcase_slug
    return if slug.blank?
    self.slug = slug.downcase
  end

  def strip_whitespace
    self.slug = self.slug.strip unless self.slug.nil?
  end

  def not_predefined_slug
    return if user.admin?

    if %w(all app new edit index session login logout
        users admin stylesheets assets javascripts
        images parti dev).include? self.slug
      errors.add(:slug, I18n.t('errors.messages.taken'))
    end
  end
end
