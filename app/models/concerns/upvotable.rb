module Upvotable
  extend ActiveSupport::Concern

  included do
    has_many :upvotes, dependent: :destroy, as: :upvotable
  end

  def upvoted_by? someone
    upvotes.exists? user: someone
  end
end
