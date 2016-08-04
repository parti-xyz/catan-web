class Group
  include ActiveModel::Model
  attr_accessor :slug, :name, :categories

  GWANGJU = Group.new(slug: 'gwangju',
    name: '광주',
    categories: [
      Category::GWANGJU_AGENDA,
      Category::GWANGJU_COMMUNITY,
      Category::GWANGJU_PROJECT,
      Category::GWANGJU_STATESMAN,
    ])

  def find_category_by_slug(slug)
    categories.detect { |c| c.slug == slug }
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
