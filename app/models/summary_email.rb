class SummaryEmail < ApplicationRecord
  SITE_WEEKLY = 1

  belongs_to :user

  def self.limit_datetime(code)
    7.days.ago
  end
end
