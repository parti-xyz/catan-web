class Group
  include ActiveModel::Model
  attr_accessor :slug, :name

  GWANGJU = Group.new(slug: 'gwangju', name: '광주')

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
