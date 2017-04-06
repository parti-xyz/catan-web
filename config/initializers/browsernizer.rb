Rails.application.config.middleware.use Browsernizer::Router do |config|
  config.supported "Internet Explorer", "11"
  config.supported "Firefox", "4"
  config.supported "Opera", "11.1"
  config.supported "Chrome", "7"

  config.location  "/no_browser.html"
  config.exclude   %r{^/assets}
end
