class CommentReader < ActiveRecord::Base
  belongs_to :user
  belongs_to :comment

  validates :user, uniqueness: { scope: :comment_id }, presence: true

  VALID_PERIOD = 1.month
  BEGIN_COMMENT_ID = 27813
end
