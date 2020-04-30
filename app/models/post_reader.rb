class PostReader < ApplicationRecord
  belongs_to :user
  belongs_to :post

  validates :user, uniqueness: { scope: :post_id }, presence: true

  VALID_PERIOD = 1.month

  def self.valid last_stroked_at
    last_stroked_at > PostReader::VALID_PERIOD.ago
  end
end
