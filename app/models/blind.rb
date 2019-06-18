class Blind < ApplicationRecord
  belongs_to :user
  belongs_to :issue, optional: true

  scope :site_wide_only, -> { where(issue: nil) }

  attr_accessor :nickname

  def self.site_wide?(someone)
    Rails.cache.fetch("Blind/#{someone&.nickname}/site_wide", race_condition_ttl: 30.seconds, expires_in: 300.seconds) do
      exists?(user: someone, issue: nil)
    end
  end
end
