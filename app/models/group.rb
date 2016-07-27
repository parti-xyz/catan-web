class Group
  include ActiveModel::Model
  attr_accessor :slug, :name

  GWANGJU = Group.new(slug: 'gwangju', name: '광주')

  def self.all
    [Group::GWANGJU]
  end
end
