class MigrateCategories < ActiveRecord::Migration
  def change
    ActiveRecord::Base.transaction do
      map = {
        Group.find_by(slug: 'gwangju') => [
          { slug: 'agenda', name: '시민의제' },
          { slug: 'project', name: '시민참여 프로젝트' },
          { slug: 'community', name: '마을' },
          { slug: 'statesman', name: '정치인' },
        ],
        Group.find_by(slug: 'meetshare') => [
          { slug: 'work', name: '일' },
          { slug: 'gender', name: '젠더' },
          { slug: 'culture', name: '컬쳐' },
          { slug: 'green', name: '환경' },
          { slug: 'life', name: '라이프' },
          { slug: 'activist', name: '활동가' }
        ]
      }
      map.each do |group, items|
        items.each do |item|
          category = group.categories.create(name: item[:name])
          group.issues.where(category_slug: item[:slug]).update_all(category_id: category.id)
        end
      end
    end
  end
end
