module Watchable
  extend ActiveSupport::Concern

  included do
    has_many :watches, as: :watchable, dependent: :destroy do
      def latest
        after(1.day.ago)
      end
    end
    has_many :watched_users, through: :watches, source: :user do
      def recent
        order('watches.created_at desc')
      end
    end
  end

  def watched_by? someone
    watches.exists? user: someone
  end

end
