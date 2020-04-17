class Blind < ApplicationRecord
  belongs_to :user
  belongs_to :issue, optional: true

  scope :site_wide_only, -> { where(issue: nil) }

  attr_accessor :nickname

  after_save :process_blind
  after_destroy :process_unblind

  def self.site_wide?(someone)
    if Rails.env.test?
      exists?(user: someone, issue: nil)
    else
      Rails.cache.fetch("Blind/#{someone&.nickname}/site_wide", race_condition_ttl: 30.seconds, expires_in: 300.seconds) do
        exists?(user: someone, issue: nil)
      end
    end
  end

  def self.any_wide?(someone)
    if Rails.env.test?
      exists?(user: someone)
    else
      Rails.cache.fetch("Blind/#{someone&.nickname}/any_wide", race_condition_ttl: 30.seconds, expires_in: 300.seconds) do
        exists?(user: someone)
      end
    end
  end

  private

  def process_blind
    BlindJob.perform_async(self.id)
  end

  def process_unblind
    UnblindJob.perform_async(self.id, self.issue_id, self.user_id)
  end
end
