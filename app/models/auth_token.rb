class AuthToken < ActiveRecord::Base
  attr_reader :token

  belongs_to :user
  before_create :init_token_and_expiration

  def athenticate token
    BCrypt::Password.new(token_digest).is_password?(token) && self
  end

  def refresh_token
    init_token_and_expiration
  end

  private

  def init_token_and_expiration
    @token = Devise.friendly_token[0,20]
    self.token_digest = BCrypt::Password.create(@token, cost: BCrypt::Engine.cost)
    self.expires_at = 60.day.from_now
    self.decays_at = 1.day.from_now
    self
  end
end
