class Group
  include ActiveModel::Model
  attr_accessor :slug, :name, :logo, :categories, :site_title, :head_title

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

  DO = Group.new(slug: 'do',
    name: '나는 알아야겠당',
    site_title: 'GMO 완전표시제법',
    head_title: 'GMO 완전표시제법 &middot; 나는 알아야겠당'.html_safe,
    categories: [
      Category::DO_COMMITTEE
    ])

  INDIE = Group.new(slug: nil, name: '전체')

  def find_category_by_slug(slug)
    categories.detect { |c| c.slug == slug }
  end

  def share_site_title
    "#{name} 빠띠"
  end

  def membership?
    self != Group::INDIE
  end

  def self.all_with_indie_and_exclude(some_group)
    Group.all_with_indie.reject {|group| group.slug == some_group.try(:slug) }
  end

  def self.all
    [Group::GWANGJU, Group::DO]
  end

  def self.all_with_indie
    all + [Group::INDIE]
  end

  def self.find_by_slug(slug)
    all.detect { |g| g.slug == slug }
  end

  def self.exists_slug?(slug)
    all.any? { |g| g.slug == slug }
  end
end
