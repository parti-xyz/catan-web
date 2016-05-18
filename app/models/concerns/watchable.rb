module Watchable
  extend ActiveSupport::Concern

  included do
    has_many :watches, as: :watchable, dependent: :destroy do
      def latest
        after(1.day.ago)
      end
    end
    has_many :watched_users, through: :watches, source: :user
  end
end
