ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'sidekiq/testing'
require 'mocha/minitest'
require 'dotenv'

Sidekiq::Testing.fake!
Sidekiq::Logging.logger = nil

class ActiveSupport::TestCase
  # load .powenv
  powenv_file_path = "#{Rails.root}/.powenv"
  if File.exist?(powenv_file_path)
    Dotenv.load(powenv_file_path)
  end

  set_fixture_class oauth_applications: Doorkeeper::Application
  set_fixture_class oauth_tokens: Doorkeeper::AccessToken
  fixtures :all
end

# class ActionDispatch::IntegrationTest
#   setup do
#     host! 'example.com'
#   end

#   CarrierWave::Mounter.class_eval { def store!; end }

#   carrierwave_root = Rails.root.join('test', 'support', 'carrierwave')

#   CarrierWave.configure do |config|
#     config.root = carrierwave_root
#     config.enable_processing = false
#     config.storage = :file
#     config.cache_dir = Rails.root.join('test', 'support', 'carrierwave', 'carrierwave_cache')
#   end

#   at_exit do
#     # puts "Removing carrierwave test directories:"
#     Dir.glob(carrierwave_root.join('*')).each do |dir|
#       # puts "   #{dir}"
#       FileUtils.remove_entry(dir)
#     end
#   end

#   def after_teardown
#     super
#     CarrierWave.clean_cached_files!(0)
#   end

#   # Returns true if a test user is logged in.
#   def signed_in?
#     !session[:user_id].nil?
#   end

#   # SignIn a test user.
#   def sign_in(user, options = {})
#     password    = options[:password]    || 'password'
#     remember_me = options[:remember_me] || '1'
#     sign_out
#     post user_session_path,
#       params: { user: { email:       user.email,
#                         password:    password,
#                         remember_me: remember_me,
#                         provider:    'email' } }
#     follow_redirect!
#   end

#   def sign_out
#     delete destroy_user_session_path
#     follow_redirect!
#   end

#   # facebook test user
#   def facebook_user1
#     @test_users ||= Koala::Facebook::TestUsers.new(app_id: ENV['FACEBOOK_APP_ID'], secret: ENV['FACEBOOK_APP_SECRET'])
#     @test_users.list.find { |u| u['id'] == '114136252377837' }
#   end

#   def fixture_file(flie_name)
#     fixture_file_upload(File.join(ActionDispatch::IntegrationTest.fixture_path, flie_name), nil, true)
#   end
# end


