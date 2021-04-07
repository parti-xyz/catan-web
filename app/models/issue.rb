class Issue < ApplicationRecord
  include Grape::Entity::DSL
  entity do
    expose :id, :title, :slug
    expose :category_id, as: :categoryId
    expose :logoUrl do |instance, options|
      instance.logo.lg.url
    end
    expose :logoXsUrl do |instance, options|
      instance.logo.xs.url
    end
    expose :logoSmUrl do |instance, options|
      instance.logo.sm.url
    end
    expose :logoMdUrl do |instance, options|
      instance.logo.md.url
    end
    expose :groupId do |instance, _|
      instance.group.id
    end
    expose :isMember do |instance, _|
      instance.member?(options[:current_user])
    end
    expose :isUnread do |instance, _|
      instance.deprecated_unread?(options[:current_user])
    end
  end

  include UniqueSoftDeletable
  acts_as_unique_paranoid
  acts_as_taggable

  SLUG_OF_PARTI_PARTI = "parti"

  include Invitable
  include Messagable

  # relations
  belongs_to :last_stroked_user, class_name: "User", optional: true
  has_many :merged_issues, dependent: :destroy
  has_many :relateds, dependent: :destroy
  has_many :issue_push_notification_preferences, dependent: :destroy
  has_many :related_issues, through: :relateds, source: :target
  has_many :relatings, class_name: "Related", foreign_key: :target_id, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :posts_pinned, -> { pinned }, class_name: "Post"
  has_many :comments, through: :posts
  #**
  #** 중요 : 아래 members를 이용하지 말고 MemberIssueService를 이용하여 가입처리를 해야합니다
  #**
  has_many :members, as: :joinable, dependent: :destroy
  has_many :member_users, through: :members, source: :user
  has_many :organizer_members, -> { where(is_organizer: true).recent }, as: :joinable, class_name: "Member" do
    def merge_nickname
      self.map { |m| m.user.nickname }.join(",")
    end
  end
  has_many :blinds, dependent: :destroy do
    def merge_nickname
      self.map { |m| m.user.nickname }.join(",")
    end
  end
  has_many :member_requests, as: :joinable, dependent: :destroy
  has_many :member_request_users, through: :member_requests, source: :user
  has_many :blind_users, through: :blinds, source: :user
  has_many :invitations, as: :joinable, dependent: :destroy
  belongs_to :destroyer, class_name: "User", optional: true
  belongs_to :group, foreign_key: :group_slug, primary_key: :slug, counter_cache: true
  has_many :active_issue_stats, dependent: :destroy
  has_many :folders, dependent: :destroy
  belongs_to :category, optional: true
  has_many :issue_post_formats, dependent: :destroy, class_name: "GroupHomeComponentPreference::IssuePostsFormat"
  belongs_to :blinded_by, class_name: "User", foreign_key: "blinded_by_id", optional: true
  has_many :last_visited_users, as: :last_visitable, class_name: "User", dependent: :nullify
  has_many :issue_readers, dependent: :destroy
  has_one :current_user_issue_reader,
    -> { where(user_id: Current.user.try(:id)) },
    class_name: 'IssueReader'
  has_many :issue_observations, dependent: :destroy, class_name: 'MessageConfiguration::IssueObservation'
  belongs_to :main_wiki_post, class_name: 'Post', optional: true
  belongs_to :main_wiki_post_by, class_name: 'User', optional: true


  # validations
  validates :title,
    presence: true,
    length: { maximum: 20 },
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
    length: { maximum: 50 }
  validate :not_parti_parti_slug

  # fields
  mount_uploader :logo, ImageUploader
  attr_accessor :organizer_nicknames
  attr_accessor :blinds_nickname

  # callbacks
  before_save :downcase_slug
  before_validation :strip_whitespace
  before_validation :valid_category
  before_validation :default_slug

  # scopes
  scope :never_blinded, -> { where(blinded_at: nil) }
  scope :blinded_only, -> { where.not(blinded_at: nil) }
  scope :alive, -> { never_blinded.where(freezed_at: nil) }
  scope :dead, -> { never_blinded.where.not(freezed_at: nil) }
  scope :only_public, -> {
          where.not(private: true).alive
        }
  scope :only_public_in_all_public_groups, -> {
          only_public.where(group_slug: Group.only_public)
        }
  scope :sort_by_name, -> { order(Arel.sql("if(ascii(substring(issues.title, 1)) < 128, 1, 0)")).order("issues.title") }
  scope :sort_default, -> { order(:position).sort_by_name }
  scope :hottest, -> { order(hot_score_datestamp: :desc, hot_score: :desc) }
  scope :this_week_or_hottest, -> { order(Arel.sql("if(issues.created_at < (NOW() - INTERVAL 6 DAY), 1, 0)")).order(hot_score_datestamp: :desc, hot_score: :desc) }
  scope :recent, -> { order(created_at: :desc) }
  scope :recent_touched, -> { order(last_stroked_at: :desc) }
  scope :categorized_with, ->(category) { where(category_id: category.try(:id) || category) }
  scope :of_group, ->(group) { never_blinded.where(group_slug: Group.slug_fallback(group)) }
  scope :only_alive_of_group, ->(group) { alive.where(group_slug: Group.slug_fallback(group)) }
  scope :displayable_in_current_group, ->(group) { never_blinded.where(group_slug: Group.slug_fallback(group)) if group.present? }
  # TODO MEMBER
  scope :deprecated_not_private_blocked, ->(current_user) {
          alive.where(id: Member.where(user: current_user).where(joinable_type: "Issue").select("members.joinable_id"))
            .or(where.not(private: true))
        }
  scope :notice_only, -> { alive.where(notice_only: true) }
  scope :only_public_hottest, ->(count) {
          where(group_slug: Group.only_public.select(:slug))
            .alive
            .where.not(private: true)
            .hottest
            .limit(count)
        }
  scope :_post_public_group_public_issues, -> {
          alive.where(group_slug: Group.only_public.select(:slug)).where.not(private: true)
        }
  scope :_public_group_public_issues, -> {
          _post_public_group_public_issues.or(alive.where(listable_even_private: true))
        }

  scope :accessible_only, ->(current_user = nil) {
          if current_user.present?
            only_public
              .or(alive.where(id: current_user.organizing_issues.select("members.joinable_id")))
          else
            only_public
          end
        }

  # TODO MEMBER
  scope :searchable_issues, ->(current_user = nil) {
          if current_user.present?
            _public_group_public_issues
              .or(where(id: current_user.organizing_issues.select("members.joinable_id")))
              .or(alive.where(id: current_user.member_issues.select("members.joinable_id")))
          else
            _public_group_public_issues
          end
        }
  # TODO MEMBER
  scope :post_searchable_issues, ->(current_user = nil) {
          if current_user.present?
            _post_public_group_public_issues
              .or(where(id: current_user.organizing_issues.select("members.joinable_id")))
              .or(alive.where(id: current_user.member_issues.select("members.joinable_id")))
          else
            _post_public_group_public_issues
          end
        }
  scope :undiscovered_issues, ->(current_user = nil) {
          conditions = _post_public_group_public_issues
          if current_user.present?
            conditions = conditions.where.not(id: current_user.member_issues.select("members.joinable_id"))
          end
          conditions
        }
  # TODO MEMBER
  scope :not_joined_issues, ->(current_user) {
          alive.where.not(id: Member.for_issues.where(user: current_user).select("members.joinable_id")) if current_user.present?
        }
  # TODO MEMBER
  scope :joined_issues, ->(current_user) {
          alive.where(id: Member.for_issues.where(user: current_user).select("members.joinable_id")) if current_user.present?
        }
  scope :only_private, -> { alive.where(private: true) }
  scope :not_private, -> { alive.where(private: false) }
  # TODO
  scope :postable, ->(someone) {
          if someone.present?
            alive.where(id: someone.organizing_issues).or(where(id: someone.member_issues, notice_only: false))
          else
            alive.where(id: nil)
          end
        }

  # search
  scoped_search on: [:title, :body]

  # methods

  def member_email?(email)
    members.joins(:user).exists? 'users.email': email
  end

  def organized_by?(someone)
    return false if someone.blank?
    cached_member = someone.cached_channel_member(self)
    return cached_member.is_organizer if cached_member.present?

    organizer_members.exists? user: someone
  end

  def member?(someone)
    return false if someone.blank?
    cached_member = someone.cached_channel_member(self)
    return true if cached_member.present?

    members.exists? user: someone
  end

  def member_requested?(someone)
    return false if someone.blank?
    member_requests.exists? user: someone
  end

  def change_group(group)
    self.group_slug = group.slug
  end

  def slug_formated_title
    return if self.title.blank?
    self.slug = self.title.strip.downcase.gsub(/\s+/, "-")
  end

  def related_with?(something)
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
    self_title.split("").each_with_index do |char, i|
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
    Group.subdomain(self.group_slug)
  end

  def postable?(someone)
    return false if someone.blank?
    return false if frozen?
    return false if blind_user?(someone)
    return false if private_blocked?(someone)
    return true if organized_by?(someone)

    if group.frontable?
      group.member?(someone) && !notice_only
    else
      member?(someone) && !notice_only
    end
  end

  def commentable?(someone)
    return false if someone.blank?
    return false if frozen?
    return false if blind_user?(someone)
    return false if private_blocked?(someone)
    return true if organized_by?(someone)

    return true
  end

  def blind_user?(someone)
    return false if someone.blank?
    blinds.exists?(user: someone) || Blind.site_wide?(someone)
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
    ActsAsTaggableOn::Tag.most_used(limit).joins(:taggings).where("taggings.taggable_type = ?", "Issue").distinct
  end

  def self.parti_parti
    find_by(slug: Issue::SLUG_OF_PARTI_PARTI, group_slug: Group::SLUG_OF_ACTIVIST)
  end

  def post_for_message
    nil
  end

  def issue_for_message
    self
  end

  def group_for_message
    self.group
  end

  def group_for_invitation
    self.group
  end

  def private_blocked?(someone = nil)
    (!member?(someone) && private?) or (self.group.private_blocked?(someone))
  end

  def host_group?(current_group)
    current_group&.slug == self.group_slug
  end

  def fallbackable_organizer_member_users
    organizer_members.present? ? organizer_members.to_a.map(&:user) : [User.find_by(nickname: "parti")]
  end

  def strok_by(someone)
    return if someone.blank?

    self.last_stroked_at = DateTime.now
    self.last_stroked_user = someone
    self
  end

  def strok_by!(someone)
    strok_by(someone).save
  end

  def sync_last_stroked_at!
    first_post = self.posts.never_blinded.order_by_stroked_at.first
    self.last_stroked_at = if first_post.present?
        first_post.last_stroked_at
      else
        first_post.created_at
      end
    self.save
  end

  def read_at(someone)
    member = someone&.smart_issue_member(self)
    member&.read_at
  end

  def marked_read_at?(someone)
    member = someone&.smart_issue_member(self)
    return false if member.blank?
    member.marked_read_at?
  end

  def need_to_read?(someone)
    return false if someone.blank?
    return false unless group.member?(someone)

    issue_reader = if someone == Current.user
      current_user_issue_reader
    else
      self.issue_readers.find_by(user: someone)
    end

    issue_reader.present? && issue_reader.updated_at < self.last_stroked_at
  end

  def deprecated_unread?(someone)
    member = someone&.smart_issue_member(self)
    member&.unread_issue?.presence || false
  end

  def deprecated_read!(someone, read_at = DateTime.now)
    member = someone&.smart_issue_member(self)
    return if member.blank?

    member.read_issue!
  end

  # DEPRECATED
  def deprecated_read_if_no_unread_posts!(someone)
    read!(someone)

    return if someone.blank?
    return unless self.marked_read_at?(someone)

    member = someone.smart_issue_member(self)
    if self.posts.next_of_date(member.read_at).where.not(last_stroked_user_id: someone.id).empty?
      self.deprecated_read!(someone)
    end
  end

  def deprecated_unread_post?(someone, last_stroked_at)
    return false if someone.blank?
    return false if last_stroked_at.blank?
    return false unless self.marked_read_at?(someone)

    member = someone.smart_issue_member(self)
    member.read_at < last_stroked_at
  end

  def issue_reader!(someone, new_sort = nil)
    fallbacked_sort = IssueReader.sort.values.include?(new_sort) ? new_sort : "stroked"

    if someone.blank? || !group.member?(someone)
      return IssueReader.new(sort: fallbacked_sort)
    end

    issue_reader = self.issue_readers.find_or_initialize_by(user: someone)
    if issue_reader.sort.blank? || new_sort.present?
      issue_reader.sort = fallbacked_sort
    end

    issue_reader.save
    issue_reader
  end

  def read!(someone)
    return if someone.blank?
    return unless group.member?(someone)

    issue_reader = issue_reader!(someone)
    if issue_reader&.persisted? && self.posts.need_to_read_only(someone).empty?
      issue_reader.update(updated_at: DateTime.now)
    end
  end

  # DEPRECATED
  def deprecated_unread_by_last_stroked_at?(someone, post_last_stroked_at)
    return false if someone.blank?
    return false if post_last_stroked_at.blank?

    member = someone.smart_issue_member(self)
    member&.deprecated_unread_issue_by_last_stroked_at?(post_last_stroked_at).presence || false
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
    !frozen?
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
    posts.exists?(["wiki_id is not ?", nil])
  end

  def movable_to_group?(target_group)
    member_users.each do |user|
      return false if !target_group.member?(user)
    end
    true
  end

  def member_of(someone)
    members.find_by(user: someone) if someone.present?
  end

  def experimental?
    group_slug == "union" and %(xyz).include?(slug)
  end

  def rookie?
    created_at > 1.weeks.ago
  end

  def self.of_group_for_message(group)
    self.of_group(group)
  end

  def top_folders
    if folders.loaded?
      Folder.array_sort_by_default(self.folders.select { |f| f.parent_id == nil })
    else
      self.folders.only_top.sort_by_default
    end
  end

  def subdomain
    self.group.subdomain
  end

  def frontable?
    self.group.frontable?
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
    if self.slug == Issue::SLUG_OF_PARTI_PARTI and self.group_slug != Group::SLUG_OF_ACTIVIST
      errors.add(:slug, I18n.t("errors.messages.taken"))
    end
  end

  def valid_category
    return if self.category_id.blank?
    if self.category_id <= 0
      self.category_id = nil
    end
    self.category = Category.find_by(id: self.category_id)
  end

  def default_slug
    return if self.slug.present?

    loop do
      temp_slug = SecureRandom.hex(20)

      next if temp_slug == Issue::SLUG_OF_PARTI_PARTI && temp_slug != Group::SLUG_OF_ACTIVIST

      next if Issue.exists?(slug: temp_slug)

      self.slug = temp_slug
      break
    end
  end
end
