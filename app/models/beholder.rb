class Beholder < ApplicationRecord
  belongs_to :user
  belongs_to :post, counter_cache: true
  belongs_to :deprecated_member, class_name: 'Member', optional: true

  scope :recent, -> { order(created_at: :desc) }
  scope :previous_of_recent, ->(beholder) {
    result = recent
    result = result.where('beholders.created_at < ?', beholder.created_at) if beholder.present?
    result
  }

  validates :user, uniqueness: { scope: :post_id }, presence: true
end
