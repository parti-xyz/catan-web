class Blind < ActiveRecord::Base
  belongs_to :user
  belongs_to :issue

  scope :site_wide_only, -> { where(issue: nil) }

  attr_accessor :nickname

  def self.site_wide?(someone)
    exists?(user: someone, issue: nil)
  end
end
