namespace :hashtag do
  desc "해시태그 재인덱싱합니다."
  task :reindex => :environment do
    Post.find_each do |post|
      post.reindex_for_hashtags!
    end
  end
end
