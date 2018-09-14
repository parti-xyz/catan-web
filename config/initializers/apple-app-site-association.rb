Apple::App::Site::Association.configure do |config|
  config.details({ appID: ENV['APPLE_APP_SITE_ASSOCIATION_APP_ID'], paths: [ '*'] })
end
