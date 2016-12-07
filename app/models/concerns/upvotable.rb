module Upvotable
  extend ActiveSupport::Concern

  included do
    has_many :upvotes, dependent: :destroy, as: :upvotable
    has_many :upvote_users, through: :upvotes, source: :user
  end

  def upvoted_by? someone
    upvotes.exists? user: someone
  end
end
