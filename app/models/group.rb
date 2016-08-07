class Group
  include ActiveModel::Model
  attr_accessor :slug, :name, :categories, :site_title, :head_title

  GWANGJU = Group.new(slug: 'gwangju',
    name: '광주',
    site_title: '민주주의 플랫폼',
    head_title: '민주주의 플랫폼 &middot; 광주빠띠'.html_safe,
    categories: [
      Category::GWANGJU_AGENDA,
      Category::GWANGJU_COMMUNITY,
      Category::GWANGJU_PROJECT,
      Category::GWANGJU_STATESMAN,
    ])

  def find_category_by_slug(slug)
    categories.detect { |c| c.slug == slug }
  end

  def share_site_title
    "#{name} 빠띠"
  end

  def self.all
    [Group::GWANGJU]
  end

  def self.find_by_slug(slug)
    all.detect { |g| g.slug == slug }
  end

  def self.exists_slug?(slug)
    all.any? { |g| g.slug == slug }
  end
end
