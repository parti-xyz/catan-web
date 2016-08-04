ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'sidekiq/testing'
require 'mocha/mini_test'

Sidekiq::Testing.fake!
Sidekiq::Logging.logger = nil

class ActiveSupport::TestCase
  fixtures :all

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
