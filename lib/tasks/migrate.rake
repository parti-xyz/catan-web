namespace :migrate do
  desc "기존에 소스로 관리하던 그룹홈 키비주얼 이미지를 DB에 넣습니다"
  task :db_group_key_visual_images => :environment do
    ActiveRecord::Base.transaction do
      Group.all.each do |group|
        ['jpg', 'gif', 'png'].each do |ext|
          image_file_path = Rails.root.join("app/assets/images/groups/#{group.slug}_thumb_main_keyvisual_bg.#{ext}")
          if image_file_path.exist?
            group.key_visual_background_image = image_file_path.open
            break
          end
        end
        ['jpg', 'gif', 'png'].each do |ext|
          image_file_path = Rails.root.join("app/assets/images/groups/#{group.slug}_thumb_main_keyvisual.#{ext}")
          if image_file_path.exist?
            group.key_visual_foreground_image = image_file_path.open
            break
          end
        end

        group.save!
      end
    end
  end

  desc "발제수다를 논의의 본문으로 옮깁니다"
  task :presetation_comment_to_talk_body => :environment do
    ActiveRecord::Base.transaction do
      Talk.where(body: nil).each do |t|
        pre_comment = t.comments.first
        next unless t.user == pre_comment.try(:user)
        t.update_columns body: pre_comment.body
        t.post.update_columns upvotes_count: pre_comment.upvotes_count
        pre_comment.upvotes.each do |upvote|
          upvote.update_columns upvotable_id: t.post.id, upvotable_type: 'Post'
        end
        pre_comment.reload
        pre_comment.destroy
      end
    end
  end

  desc "자료의 첫 댓글을 자료 본문으로 옮깁니다"
  task :first_comment_to_article_body => :environment do
    ActiveRecord::Base.transaction do
      Article.where(body: nil).each do |t|
        pre_comment = t.comments.first
        next unless t.user == pre_comment.try(:user)
        t.update_columns body: pre_comment.body
        t.post.update_columns upvotes_count: pre_comment.upvotes_count
        pre_comment.upvotes.each do |upvote|
          upvote.update_columns upvotable_id: t.post.id, upvotable_type: 'Post'
        end
        pre_comment.reload
        pre_comment.destroy
      end
    end
  end

  desc "업로드된 파일을 새로운 비밀s3로 옮깁니다"
  task :move_new_private_s3 => :environment do
    FileSource.where(secure_attachment: nil).each do |file_source|
      begin
        file_source.remote_secure_attachment_url = file_source.attachment.url
        file_source.save!

        print "."
      rescue => e
        puts "fail: #{file_source.id} #{file_source.name}"
        puts e.inspect
      end
    end
  end
end
