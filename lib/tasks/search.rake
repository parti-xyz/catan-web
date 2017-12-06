namespace :search do
  desc "재인덱싱합니다."
  task :reindex => :environment do
    Post.find_each do |post|
      post.reindex_for_search!
    end
  end
end
