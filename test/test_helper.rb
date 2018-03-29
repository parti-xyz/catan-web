ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'sidekiq/testing'
require 'mocha/mini_test'

Sidekiq::Testing.fake!
Sidekiq::Logging.logger = nil

module CatanTestHelpers
  def fixture_file(flie_name)
    fixture_file_upload(File.join(ActionController::TestCase.fixture_path, flie_name), nil, true)
  end
end

class ActiveSupport::TestCase
  # load .powenv
  if File.exist?("#{Rails.root}/.powenv")
    IO.foreach("#{Rails.root}/.powenv") do |line|
      next if !line.include?('export') || line.blank?
      key, value = line.gsub('export','').split('=',2)
      ENV[key.strip] = value.delete('"\'').strip
    end
  end

  set_fixture_class oauth_applications: Doorkeeper::Application
  set_fixture_class oauth_tokens: Doorkeeper::AccessToken
  fixtures :all

  include CatanTestHelpers

  CarrierWave::Mounter.class_eval { def store!; end }

  carrierwave_template = Rails.root.join('test','fixtures','files')
  carrierwave_root = Rails.root.join('test','support','carrierwave')

  CarrierWave.configure do |config|
    config.root = carrierwave_root
    config.enable_processing = false
    config.storage = :file
    config.cache_dir = Rails.root.join('test','support','carrierwave','carrierwave_cache')
  end

  at_exit do
    #puts "Removing carrierwave test directories:"
    Dir.glob(carrierwave_root.join('*')).each do |dir|
      #puts "   #{dir}"
      FileUtils.remove_entry(dir)
    end
  end

  def after_teardown
    super
    CarrierWave.clean_cached_files!(0)
  end

  # Returns true if a test user is logged in.
  def signed_in?
    !session[:user_id].nil?
  end

  # Logs in a test user.
  def sign_in(user, options = {})
    password    = options[:password]    || 'password'
    remember_me = options[:remember_me] || '1'
    if integration_test?
      sign_out
      post_via_redirect user_session_path, user: { email:       user.email,
                                                   password:    password,
                                                   remember_me: remember_me,
                                                   provider:    'email' }
    else
      session[:user_id] = user.id
    end
  end

  def sign_out
    delete_via_redirect destroy_user_session_path
  end

  # facebook test user
  def facebook_user1
    @test_users ||= Koala::Facebook::TestUsers.new(app_id: ENV['FACEBOOK_APP_ID'], secret: ENV['FACEBOOK_APP_SECRET'])
    @test_users.list.find { |u| u["id"] == "114136252377837" }
  end

  private

  # Returns true inside an integration test.
  def integration_test?
    defined?(post_via_redirect)
  end
end

class ActionController::TestCase
  include Devise::Test::ControllerHelpers
end

class ActionDispatch::IntegrationTest
  setup do
    host! 'example.com'
  end
end


