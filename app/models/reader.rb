class Reader < ApplicationRecord
  belongs_to :user
  belongs_to :post, counter_cache: true
  belongs_to :deprecated_member, class_name: 'Member', optional: true

  scope :recent, -> { order(created_at: :desc) }
  scope :previous_of_recent, ->(reader) {
    base = recent
    base = base.where('readers.created_at < ?', reader.created_at) if reader.present?
    base
  }

  validates :user, uniqueness: { scope: :post_id }, presence: true
end
