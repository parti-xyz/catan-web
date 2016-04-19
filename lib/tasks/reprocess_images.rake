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
end
