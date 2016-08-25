class Category
  include ActiveModel::Model
  attr_accessor :slug, :name

  GWANGJU_AGENDA = Category.new(slug: 'agenda', name: '시민의제')
  GWANGJU_PROJECT = Category.new(slug: 'project', name: '시민참여 프로젝트')
  GWANGJU_COMMUNITY = Category.new(slug: 'community', name: '마을')
  GWANGJU_STATESMAN = Category.new(slug: 'statesman', name: '정치인')

end
