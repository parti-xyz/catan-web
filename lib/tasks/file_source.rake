namespace :file_source do
  desc "업로드된 이미지의 높이와 가로 크기를 계산합니다"
  task :estimate_size => :environment do
    FileSource.only_image.where.any_of('image_height <= 0', 'image_width <= 0').limit(1000).find_each do |file_source|
      begin
        image = MiniMagick::Image.open(file_source.url)
      rescue
        next
      end
      file_source.update_columns(image_width: image[:width], image_height: image[:height])
    end
  end
end
