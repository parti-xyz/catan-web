namespace :images do
  desc "Reprocess"
  task :reprocess => :environment do
    ActiveRecord::Base.record_timestamps = false
    begin
      { Issue => [:logo, :cover], LinkSource => [:image],
        Post => [:social_card], User => [:image] }.each do |clazz, attributes|
        attributes.each do |attribute|
          puts "#{clazz} #{attribute}"
          begin
            clazz.find_each do |model|
              if model.send(attribute).present?
                model.send(attribute).try(:recreate_versions!)
                model.save!
              end
            end
          rescue
          end
        end
      end
    ensure
      ActiveRecord::Base.record_timestamps = true
    end
  end

  desc "LinkSource image size"
  task :load_size_link_sources => :environment do
    ActiveRecord::Base.record_timestamps = false
    begin
      LinkSource.find_each do |link_source|
        next if link_source.image.blank?

        file = link_source.image.file
        next if !file.exists?

        size = FastImage.new(file.respond_to?(:url) ? file.url : file.path).size
        if size.present?
          link_source.update_columns(image_width: size[0], image_height: size[1])
        end
      end
    ensure
      ActiveRecord::Base.record_timestamps = true
    end
  end
end
