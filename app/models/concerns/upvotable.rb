module Upvotable
  extend ActiveSupport::Concern

  included do
    has_many :upvotes, dependent: :destroy, as: :upvotable
    has_many :upvote_users, through: :upvotes, source: :user
    has_many :current_user_upvotes,
    -> { where(user_id: Current.user.try(:id)) },
    class_name: "Upvote", as: :upvotable
  end

  def upvoted_by? someone
    upvotes.exists? user: someone
  end

  def upvoted_by_me?
    smart_exists_association?(:current_user_upvotes)
  end
end
