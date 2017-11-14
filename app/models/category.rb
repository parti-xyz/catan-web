class Category
  include ActiveModel::Model
  attr_accessor :slug, :name

  GWANGJU_AGENDA = Category.new(slug: 'agenda', name: '시민의제')
  GWANGJU_PROJECT = Category.new(slug: 'project', name: '시민참여 프로젝트')
  GWANGJU_COMMUNITY = Category.new(slug: 'community', name: '마을')
  GWANGJU_STATESMAN = Category.new(slug: 'statesman', name: '정치인')

  MEETSHARE_WORK = Category.new(slug: 'work', name: '일')
  MEETSHARE_GENDER = Category.new(slug: 'gender', name: '젠더')
  MEETSHARE_CULTURE = Category.new(slug: 'culture', name: '컬쳐')
  MEETSHARE_GREEN = Category.new(slug: 'green', name: '환경')
  MEETSHARE_LIFE = Category.new(slug: 'life', name: '라이프')
  MEETSHARE_ACTIVIST = Category.new(slug: 'activist', name: '활동가')

end
