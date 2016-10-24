class Group
  include ActiveModel::Model
  attr_accessor :slug, :name, :logo, :categories, :site_title, :head_title

  GWANGJU = Group.new(slug: 'gwangju',
    name: '광주',
    site_title: '민주주의 플랫폼',
    head_title: '민주주의 플랫폼 - 광주빠띠'.html_safe,
    categories: [
      Category::GWANGJU_AGENDA,
      Category::GWANGJU_COMMUNITY,
      Category::GWANGJU_PROJECT,
      Category::GWANGJU_STATESMAN,
    ])

  DO = Group.new(slug: 'do',
    name: '나는 알아야겠당',
    site_title: 'GMO 완전표시제법',
    head_title: 'GMO 완전표시제법 - 나는 알아야겠당'.html_safe)


  DUCKUP = Group.new(slug: 'duckup',
    name: '덕업넷',
    site_title: '덕후들 모여라',
    head_title: '덕후들 모여라 - 덕업넷'.html_safe)

  CHANGE = Group.new(slug: 'change',
    name: '바꿈',
    site_title: '세상을 바꾸는 꿈',
    head_title: '세상을 바꾸는 꿈 - 바꿈'.html_safe)

  TOKTOK = Group.new(slug: 'toktok',
    name: '국회톡톡',
    site_title: '내게 필요한 법, 국회에 직접 제안해서 만들어봐요',
    head_title: '내게 필요한 법, 국회에 직접 제안해서 만들어봐요 - 국회톡톡'.html_safe)

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
    [Group::GWANGJU, Group::DO, Group::DUCKUP, Group::CHANGE, Group::TOKTOK]
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
