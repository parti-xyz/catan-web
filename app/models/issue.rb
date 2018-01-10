class Issue < ActiveRecord::Base
  include Grape::Entity::DSL
  entity :id, :title, :body, :slug, :updated_at do
    include Rails.application.routes.url_helpers
    include PartiUrlHelper

    expose :group, using: Group::Entity
    expose :logo, as: :logo_url do |instance|
      instance.logo.xs.url
    end
    # expose :latest_members_count do |instance|
    #   instance.members.latest.count
    # end
    # expose :latest_posts_count do |instance|
    #   instance.posts.latest.count
    # end
    # expose :members_count do |instance|
    #   instance.members.count
    # end
    # expose :posts_count do |instance|
    #   instance.posts.count
    # end

    with_options(if: lambda { |instance, options| options[:current_user].present? }) do
      expose :is_member do |instance, options|
        instance.member? options[:current_user]
      end
      expose :is_organized_by do |instance, options|
        instance.organized_by? options[:current_user]
      end
      expose :is_postable do |instance, options|
        instance.postable? options[:current_user]
      end
    end

    with_options(if: lambda { |instance, options| options[:target_user].present? }) do
      expose :is_member_by_target_user do |instance, options|
        instance.member? options[:target_user]
      end
      expose :is_organized_by_target_user do |instance, options|
        instance.organized_by? options[:target_user]
      end
    end

    # expose :share do
    #   expose :url do |instance|
    #     smart_issue_home_url(instance)
    #   end
    #   expose :twitter_text do |instance|
    #     instance.title
    #   end

    #   expose :kakaotalk_text do |instance|
    #     instance.title
    #   end
    #   expose :kakaotalk_link_text do |instance|
    #     "빠띠로 이동하기"
    #   end

    #   with_options(if: lambda { |instance, options| instance.share_image_dimensions.present? }) do
    #     expose :kakaotalk_image_url do |instance|
    #       instance.share_image_url
    #     end
    #     expose :kakaotalk_image_width do |instance|
    #       instance.share_image_dimensions[0]
    #     end
    #     expose :kakaotalk_image_height do |instance|
    #       instance.share_image_dimensions[1]
    #     end
    #   end
    # end
  end

  include UniqueSoftDeletable
  acts_as_unique_paranoid
  acts_as_taggable

  SLUG_OF_PARTI_PARTI = 'parti'

  # relations
  belongs_to :last_stroked_user, class_name: User
  has_many :merged_issues, dependent: :destroy
  has_many :relateds, dependent: :destroy
  has_many :related_issues, through: :relateds, source: :target
  has_many :relatings, class_name: Related, foreign_key: :target_id, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :comments, through: :posts
  has_many :members, as: :joinable, dependent: :destroy
  has_many :member_users, through: :members, source: :user
  has_many :organizer_members, -> { where(is_organizer: true) }, as: :joinable, class_name: Member do
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
  belongs_to :destroyer, class_name: User
  belongs_to :group, foreign_key: :group_slug, primary_key: :slug

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
  scope :alive, -> { where(freezed_at: nil) }
  scope :only_public_in_current_group, ->(current_group = nil) {
    result = where.not(private: true).alive
    if current_group.blank?
      result = result.joins(:group).where.not('groups.private': true)
    end
    result
  }
  scope :sort_by_name, -> { order("if(ascii(substring(issues.title, 1)) < 128, 1, 0)").order('issues.title') }
  scope :hottest, -> { order(hot_score_datestamp: :desc, hot_score: :desc) }
  scope :recent, -> { order(created_at: :desc) }
  scope :recent_touched, -> { order(last_stroked_at: :desc) }
  scope :categorized_with, ->(slug) { where(category_slug: slug) }
  scope :of_group, ->(group) { where(group_slug: Group.default_slug(group)) }
  scope :only_alive_of_group, ->(group) { alive.where(group_slug: Group.default_slug(group)) }
  scope :displayable_in_current_group, ->(group) { where(group_slug: Group.default_slug(group)) if group.present? }
  scope :not_private_blocked, ->(current_user) { where.any_of(
                                                    where(id: Member.where(user: current_user).where(joinable_type: 'Issue').select('members.joinable_id')),
                                                    where.not(private: true)) }
  scope :not_in_dashboard, ->(current_user) { where.not(id: Member.where(user: current_user).where(joinable_type: 'Issue').select('members.joinable_id'))
                                             .where.not('issues.private': true) }
  scope :hottest_not_private_blocked_of_group, ->(group, someone, count = 10) {
    of_group(group).not_private_blocked(someone).hottest.limit(count)
  }
  scope :notice_only, -> { where(notice_only: true) }
  scope :only_public_hottest, ->(count){
    where.any_of(where(group_slug: Group.where.not(private: true).select(:slug)), where(group_slug: 'indie'))
    .where.not(private: true)
    .hottest
    .limit(count)
  }
  scope :searchable_issues, ->(current_user) {
    public_group_public_issues = where(group_slug: Group.where.not(private: true).select(:slug)).where.not(private: true)
    indie_public_issues = where(group_slug: 'indie').where.not(private: true)
    if current_user.present?
      where.any_of(public_group_public_issues, indie_public_issues,
                   where(id: current_user.member_issues.select("members.joinable_id")))
    else
      where.any_of(public_group_public_issues, indie_public_issues)
    end
  }

  # search
  scoped_search on: [:title, :body]

  # methods

  def member_email? email
    members.joins(:user).exists? 'users.email': email
  end

  def organized_by? someone
    organizer_members.exists? user: someone
  end

  def member? someone
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

  def indie_group?
    group.indie?
  end

  def postable? someone
    return true if organized_by?(someone)
    member?(someone) and !notice_only
  end

  def blind_user? someone
    blinds.exists?(user: someone) or Blind.site_wide?(someone)
  end

  def safe_postable? someone
    return false if blind_user?(someone)
    postable? someone
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
    self.find_by(slug: slug, group_slug: Group.default_slug(group_slug))
  end

  def self.most_used_tags(limit)
    ActsAsTaggableOn::Tag.where('taggings.taggable_type': 'Issue').most_used(limit).joins(:taggings).select('name').distinct
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

  def displayable_group?(current_group)
    if self.group.indie?
      current_group.blank?
    else
      current_group == self.group
    end
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

    update_columns(last_stroked_at: DateTime.now, last_stroked_user_id: someone)
    IssueFirebaseRealtimeDb.perform_async(self.id, someone.id)
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
    return true if target_group.indie?
    member_users.each do |user|
      return false if !target_group.member?(user)
    end
    true
  end

  def of_public_group?
    return true if group.indie? or !group.private
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
