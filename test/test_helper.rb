ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'sidekiq/testing'
require 'mocha/mini_test'

Sidekiq::Testing.fake!
Sidekiq::Logging.logger = nil

class CarrierWave::Mount::Mounter
  def store!
    # Not storing uploads in the tests
  end
end

module CatanTestHelpers
  def fixture_file(flie_name)
    fixture_file_upload(File.join(ActionController::TestCase.fixture_path, flie_name), nil, true)
  end
end

class ActiveSupport::TestCase
  fixtures :all

  include CatanTestHelpers

  CarrierWave.root = Rails.root.join('test/fixtures/files')

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
      post_via_redirect user_session_path, user: { email:       user.email,
                                                   password:    password,
                                                   remember_me: remember_me,
                                                   provider:    'email' }
    else
      session[:user_id] = user.id
    end
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
