namespace :images do
  desc "Reprocess"
  task :reprocess => :environment do
    { Issue => [:logo, :cover], LinkSource => [:image],
      Post => [:social_card], User => [:image] }.each do |clazz, attributes|
      attributes.each do |attribute|
        puts "#{clazz} #{attribute}"
        begin
          clazz.all.each { |model| model.send(attribute).try(:recreate_versions!) if model.send(attribute).present? }
        rescue CarrierWave::ProcessingError
        end
      end
    end
  end
end
