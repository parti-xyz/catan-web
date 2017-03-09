class Group < ActiveRecord::Base
  include Grape::Entity::DSL
  entity :title, :slug

  include UniqueSoftDeletable
  acts_as_unique_paranoid

  mount_uploader :logo, ImageUploader
  mount_uploader :cover, ImageUploader

  belongs_to :user
  has_many :members, as: :joinable, dependent: :destroy
  has_many :organizer_members, -> { where(is_organizer: true) }, as: :joinable, class_name: Member
  has_many :member_users, through: :members, source: :user
  has_many :member_requests, as: :joinable, dependent: :destroy
  has_many :member_request_users, through: :member_requests, source: :user

  default_scope -> { order("case when slug = 'indie' then 0 else 1 end").order("if(ascii(substring(title, 1)) < 128, 1, 0)").order(:title) }

  def find_category_by_slug(slug)
    categories.detect { |c| c.slug == slug }
  end

  def share_site_title
    "#{title} 빠띠"
  end

  def categories
    if slug == 'gwangju'
      [
        Category::GWANGJU_AGENDA,
        Category::GWANGJU_COMMUNITY,
        Category::GWANGJU_PROJECT,
        Category::GWANGJU_STATESMAN,
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

  def parti_putable_by? someone
    indie? or organized_by?(someone) or someone.admin?
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
      title
    end
  end

  def title
    read_attribute(:title) || read_attribute(:name)
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

  def self.joined_by(someone)
    someone.member_issues.map(&:group).uniq.compact
  end

  def self.all_but(some_group)
    Group.all.reject { |group| group.slug == Group.default_slug(some_group) }
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
end
