class Group < ActiveRecord::Base
  attr_accessor :organizer_nicknames

  include Grape::Entity::DSL
  entity :title, :slug

  include UniqueSoftDeletable
  acts_as_unique_paranoid

  include Invitable

  extend Enumerize
  enumerize :plan, in: [:premium, :lite], predicates: true, scope: true

  mount_uploader :logo, ImageUploader
  mount_uploader :cover, ImageUploader

  SLUG_OF_UNION = 'union'

  belongs_to :user
  has_many :invitations, as: :joinable, dependent: :destroy
  has_many :members, as: :joinable, dependent: :destroy
  has_many :organizer_members, -> { where(is_organizer: true) }, as: :joinable, class_name: Member do
    def merge_nickname
      self.map { |m| m.user.nickname }.join(',')
    end
  end
  has_many :member_users, through: :members, source: :user
  has_many :member_requests, as: :joinable, dependent: :destroy
  has_many :member_request_users, through: :member_requests, source: :user
  has_many :issues, dependent: :restrict_with_error, primary_key: :slug, foreign_key: :group_slug

  scope :sort_by_name, -> { order("case when slug = 'indie' then 0 else 1 end").order("if(ascii(substring(title, 1)) < 128, 1, 0)").order(:title) }
  scope :but, ->(group) { where.not(id: group) }
  scope :not_private_blocked, ->(current_user) { where.any_of(
                                                    where(id: Member.where(user: current_user).where(joinable_type: 'Group').select('members.joinable_id')),
                                                    where.not(private: true)) }
  mount_uploader :logo, ImageUploader

  validates :title,
    presence: true,
    length: { maximum: 20 },
    uniqueness: { case_sensitive: false }
  validates :site_description,
    length: { maximum: 200 }
  VALID_SLUG = /\A[a-z][a-z0-9_-]+\z/i
  validates :slug,
    presence: true,
    format: { with: VALID_SLUG },
    uniqueness: { case_sensitive: false },
    length: { maximum: 20 }
  validate :not_predefined_slug
  validates :head_title,
    presence: true,
    uniqueness: { case_sensitive: false },
    length: { maximum: 5 }
  validates :site_title,
    presence: true,
    length: { maximum: 50 }

  def find_category_by_slug(slug)
    categories.detect { |c| c.slug == slug }
  end

  def title_share_format
    indie? ? nil : "#{title} 빠띠"
  end

  def title_basic_format
    indie? ? "빠띠" : "#{title} 그룹"
  end

  def title_short_format
    indie? ? "빠띠" : title
  end

  def categorized_issues(category = nil)
    issues.categorized_with(category.try(:slug))
  end

  def categories
    if slug == 'gwangju'
      [
        Category::GWANGJU_AGENDA,
        Category::GWANGJU_COMMUNITY,
        Category::GWANGJU_PROJECT,
        Category::GWANGJU_STATESMAN,
      ]
    elsif slug == 'meetshare'
      [
        Category::MEETSHARE_WORK,
        Category::MEETSHARE_GENDER,
        Category::MEETSHARE_CULTURE,
        Category::MEETSHARE_GREEN,
        Category::MEETSHARE_LIFE,
        Category::MEETSHARE_ACTIVIST
      ]
    else
      []
    end
  end

  def private_blocked?(someone = nil)
    !member?(someone) && private?
  end

  def organized_by? someone
    organizer_members.exists? user: someone
  end

  def member? someone
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
    Group.none if someone.blank?
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

  PRIVATE_ISSUE_QUOTA_FOR_LITE_PLAN = 5
  def met_private_issues_quota?
    return false unless has_private_issues_quota?
    issues.only_private.count >= Group::PRIVATE_ISSUE_QUOTA_FOR_LITE_PLAN
  end

  def has_private_issues_quota?
    return false if indie?
    plan == :lite
  end

  def changable_private_for_issue?(issue)
    return true unless has_private_issues_quota?
    return true if issue.private?

    !met_private_issues_quota?
  end

  private

  def not_predefined_slug
    return if user.admin?

    if %w(all app new edit index session login logout
        users admin stylesheets assets javascripts
        images parti dev).include? self.slug
      errors.add(:slug, I18n.t('errors.messages.taken'))
    end
  end
end
