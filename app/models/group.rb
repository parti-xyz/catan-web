class Group < ApplicationRecord
  attr_accessor :organizer_nicknames

  include UniqueSoftDeletable
  acts_as_unique_paranoid

  include Invitable

  extend Enumerize
  enumerize :plan, in: [:premium, :lite, :trial], predicates: true, scope: true
  enumerize :issue_creation_privileges, in: [:member, :organizer], predicates: true, scope: true
  SLUG_OF_UNION = 'union'

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
  belongs_to :front_wiki_post, class_name: 'Post', optional: true
  belongs_to :front_wiki_post_by, class_name: 'User', optional: true

  scope :sort_by_name, -> { order(Arel.sql("case when slug = 'indie' then 0 else 1 end")).order(Arel.sql("if(ascii(substring(title, 1)) < 128, 1, 0)")).order(:title) }
  scope :hottest, -> { order(Arel.sql("case when slug = 'indie' then 0 else 1 end")).order(hot_score_datestamp: :desc, hot_score: :desc) }
  scope :but, ->(group) { where.not(id: group) }
  scope :not_private_blocked, ->(current_user) {
    where(id: Member.where(user: current_user).where(joinable_type: 'Group').select('members.joinable_id'))
    .or(where.not(private: true))
  }
  scope :memberable_and_unfamiliar, ->(current_user) {
    where.not(id: Member.where(user: current_user).where(joinable_type: 'Group').select('members.joinable_id'))
    .where.not(private: true).where.not(slug: 'indie').where('issues_count > 0')
  }
  mount_uploader :key_visual_foreground_image, ImageUploader
  mount_uploader :key_visual_background_image, ImageUploader

  validates :title,
    presence: true,
    length: { maximum: 20 },
    uniqueness: { case_sensitive: false }
  validates :site_description,
    length: { maximum: 200 }
  VALID_SLUG = /\A[a-z][a-z0-9-]+\z/i
  validates :slug,
    presence: true,
    format: { with: VALID_SLUG },
    exclusion: { in: %w(all app new edit index session login logout users admin stylesheets assets javascripts images) },
    uniqueness: { case_sensitive: false },
    length: { maximum: 20 }
  validate :not_predefined_slug
  validates :head_title,
    presence: true,
    uniqueness: { case_sensitive: false },
    length: { maximum: 10 }
  validates :site_title,
    presence: true,
    length: { maximum: 50 }

  # callbacks
  before_save :downcase_slug
  before_validation :strip_whitespace

  def title_share_format
    indie? ? nil : "#{title} 빠띠"
  end

  def title_basic_format
    indie? ? "빠띠" : "#{title} 그룹"
  end

  def title_short_format
    indie? ? "빠띠" : title
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
    members.find_by(user: someone)
  end

  def form_select_title
    if indie?
      I18n.t('views.indie_form_select_title')
    else
      head_title
    end
  end

  def site_title
    read_attribute(:site_title) || read_attribute(:title)
  end

  def member_requested?(someone)
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
    indie? ? nil : self.slug
  end

  def indie?
    self.slug == 'indie'
  end

  def out_of_member_users member_users
    member_users.to_a.select { |user| !member?(user) }
  end

  def comprehensive_joined_by?(someone)
    Group.comprehensive_joined_by(someone).exists?(id: self)
  end

  def default_issues
    issues.where(is_default: true)
  end

  def is_light_theme?
    %(indie).include?(self.slug)
  end

  def comprehensive_joined_users
    User.where(id: Member.where(joinable: self.issues).select(:user_id))
  end

  def self.comprehensive_joined_by(someone)
    return Group.none if someone.blank?
    self.where(slug: (someone.member_issues.select(:group_slug)))
        .or(self.where(id: someone.member_groups))
  end

  def self.find_by_slug(slug)
    find_by(slug: slug)
  end

  def self.exists_slug?(slug)
    exists? slug: slug
  end

  def self.default_slug(current_group)
    current_group.try(:slug) || (current_group if current_group.is_a?(String)) || 'indie'
  end

  def self.indie
    find_by(slug: 'indie')
  end

  def pinned_posts(someone)
    noticed_issues = self.issues.only_public_in_current_group.to_a
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
    elsif %w(slowalk westay1 Group::SLUG_OF_UNION adaptiveleadership youthpolicynet).include? slug
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
    return false if indie?
    plan == :lite
  end

  def changable_private_for_issue?(issue)
    return true unless has_issues_quota?
    return true if issue.private?
    return true if private?
    !met_issues_quota?
  end

  def visiable_latest_stroked_posts_count
    (LatestStrokedPostsCountHelper.current_version == latest_stroked_posts_count_version ? latest_stroked_posts_count : 0)
  end

  def visiable_latest_issues_count
    (LatestStrokedPostsCountHelper.current_version == latest_issues_count_version ? latest_issues_count : 0)
  end

  def creatable_issue?(someone)
    return true if self.indie?
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
