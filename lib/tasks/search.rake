namespace :search do
  desc "index"
  task :index => :environment do
    IndexingJob.perform_async
  end
end
