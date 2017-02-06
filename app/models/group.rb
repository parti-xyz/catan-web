class Group < ActiveRecord::Base
  include Grape::Entity::DSL
  entity :name, :slug

  include UniqueSoftDeletable
  acts_as_unique_paranoid

  # GWANGJU = Group.new(slug: 'gwangju',
  #   name: '광주',
  #   site_title: '민주주의 플랫폼',
  #   head_title: '민주주의 플랫폼 - 광주빠띠'.html_safe,
  #   categories: [
  #     Category::GWANGJU_AGENDA,
  #     Category::GWANGJU_COMMUNITY,
  #     Category::GWANGJU_PROJECT,
  #     Category::GWANGJU_STATESMAN,
  #   ])

  # DO = Group.new(slug: 'do',
  #   name: '나는 알아야겠당',
  #   site_title: 'GMO 완전표시제법',
  #   head_title: 'GMO 완전표시제법 - 나는 알아야겠당'.html_safe)

  # DUCKUP = Group.new(slug: 'duckup',
  #   name: '덕업넷',
  #   site_title: '덕후들 모여라',
  #   head_title: '덕후들 모여라 - 덕업넷'.html_safe)

  # CHANGE = Group.new(slug: 'change',
  #   name: '바꿈',
  #   site_title: '세상을 바꾸는 꿈',
  #   head_title: '세상을 바꾸는 꿈 - 바꿈'.html_safe)

  # TOKTOK = Group.new(slug: 'toktok',
  #   name: '국회톡톡',
  #   site_title: '내게 필요한 법, 국회에 직접 제안해서 만들어봐요',
  #   head_title: '내게 필요한 법, 국회에 직접 제안해서 만들어봐요 - 국회톡톡'.html_safe)

  # INNOVATORS = Group.new(slug: 'innovators',
  #   name: 'N명의 사회혁신가',
  #   site_title: '함께 새로운 세상을 만들자',
  #   head_title: '함께 새로운 세상을 만들자 - N명의 사회혁신가',
  #   site_description: '사회혁신가는 일상에서 대안과 해결책을 고민하고 제안하며, 구체적인 그림과 방법을 연구하고, 각자의 현장에서 실천하고자 하는 사람들입니다.',
  #   site_keywords: '함께, 새로운세상을, 만들자, 사회혁신가, 소셜벤처, 박근혜게이트, 정치, 시국선언'.html_safe)

  INDIE = Group.new(slug: nil, name: '전체')

  mount_uploader :logo, ImageUploader
  mount_uploader :cover, ImageUploader

  belongs_to :user

  def find_category_by_slug(slug)
    categories.detect { |c| c.slug == slug }
  end

  def share_site_title
    "#{name} 빠띠"
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

  def self.joined_by(someone)
    someone.member_issues.map(&:group).uniq.compact
  end

  def self.all_with_indie_and_exclude(some_group)
    Group.all_with_indie.reject {|group| group.slug == some_group.try(:slug) }
  end

  def self.all_with_indie
    all + [Group::INDIE]
  end

  def self.find_by_slug(slug)
    find_by(slug: slug)
  end

  def self.exists_slug?(slug)
    exists? slug: slug
  end
end
