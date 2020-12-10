class ClearOldGroupExportsJob < ApplicationJob
  include Sidekiq::Worker

  EXPIRED_TIME = 2.hours

  def perform
    if ExportGroupJob.remote_exportable?
      with_s3
    else
      with_local_files
    end
  end

  def with_s3
    s3_client = Aws::S3::Client.new(
      region: ENV['PRIVATE_S3_REGION'],
      access_key_id: ENV['PRIVATE_S3_ACCESS_KEY'],
      secret_access_key: ENV['PRIVATE_S3_SECRET_KEY'],
    )
    s3_response = s3_client.list_objects(bucket: ENV['PRIVATE_S3_BUCKET'], prefix: "exports/#{Rails.env}/")
    s3_response.contents.each do |s3_object|
      next if (Time.current - s3_object.last_modified) < EXPIRED_TIME
      s3_client.delete_object(bucket: ENV['PRIVATE_S3_BUCKET'], key: s3_object.key)
      Rails.logger.info("Expired file: #{s3_object.key}")
    end
  end

  def with_local_files
    Dir[ExportGroupJob.export_base_path.join('*')].each do |file|
      created_time = File::Stat.new(file).ctime
      next if (Time.current - created_time) < EXPIRED_TIME

      FileUtils.rm file
      Rails.logger.info("Expired file: #{file}")
    end
  end
end
