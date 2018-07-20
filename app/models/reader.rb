class Reader < ApplicationRecord
  belongs_to :member
  belongs_to :post, counter_cache: true

  scope :recent, -> { order(created_at: :desc) }
  scope :previous_of_recent, ->(reader) {
    base = recent
    base = base.where('readers.created_at < ?', reader.created_at) if reader.present?
    base
  }

  def user
    member.user
  end
end
