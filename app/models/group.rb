class Group < ActiveRecord::Base
  include Grape::Entity::DSL
  entity :title, :slug

  include UniqueSoftDeletable
  acts_as_unique_paranoid

  mount_uploader :logo, ImageUploader
  mount_uploader :cover, ImageUploader

  belongs_to :user
  has_many :members, as: :joinable, dependent: :destroy
  has_many :member_users, through: :members, source: :user
  has_many :makers, as: :makable, dependent: :destroy
  has_many :member_requests, as: :joinable, dependent: :destroy
  has_many :member_request_users, through: :member_requests, source: :user

  default_scope -> { order :slug }

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

  def made_by? someone
    makers.exists? user: someone
  end

  def member? someone
    members.exists? user: someone
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
    Group.all.reject { |group| group.slug == some_group.try(:slug) }
  end

  def self.find_by_slug(slug)
    find_by(slug: slug)
  end

  def self.exists_slug?(slug)
    exists? slug: slug
  end
end
