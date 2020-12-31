class CommentHistory < ApplicationRecord
  belongs_to :user
  belongs_to :comment, counter_cache: true

  scope :significant, -> { where(trivial_update_body: false) }

  include Historyable
  def sibling_histories
    comment.comment_histories
  end

  def diffable_body
    body
  end

  def trivial?
    touched_body? && trivial_update_body?
  end

  def touched_body?
    'update_body' == code
  end
end
