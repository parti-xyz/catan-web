require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CatanWeb
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.eager_load_paths += %W(#{config.root}/lib)

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    config.time_zone = 'Asia/Seoul'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.i18n.available_locales = [:en, :ko]
    config.i18n.default_locale = :ko

    config.active_job.queue_adapter = ((!ENV['SIDEKIQ'] and (Rails.env.test? or Rails.env.development?)) ? :inline : :sidekiq)

    if Rails.env.test? || Rails.env.development?
        config.asset_host = 'https://parti.test'
    elsif Rails.env.staging?
        config.asset_host = 'https://dev.parti.xyz'
    else
        config.asset_host = 'https://parti.xyz'
    end

    I18n.backend.class.send(:include, I18n::Backend::Cascade)

    config.tinymce.install = :compile

    config.middleware.insert_before 0, Rack::Cors, debug: (!Rails.env.production?), logger: (-> { Rails.logger }) do
      allow do
        origins '*'
        resource '/assets/*', :headers => :any, :methods => :get
      end

      allow do
        origins /\Ahttps?:\/\/(.*?)\.?parti\.test\z/
        resource '*', :headers => :any, :methods => :any, :credentials => true
      end

      allow do
        origins /\Ahttps?:\/\/(.*?)\.?parti\.xyz\z/
        resource '*', :headers => :any, :methods => :any, :credentials => true
      end
    end
  end
end
