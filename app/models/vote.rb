class Vote < ActiveRecord::Base
  extend Enumerize
  include Choosable

  belongs_to :user
  belongs_to :post, counter_cache: true

  validates :user, uniqueness: {scope: [:post]}
  validates :post, presence: true
  validates :choice, presence: true

  scope :recent, -> { order(updated_at: :desc) }
  scope :latest, -> { after(1.day.ago) }
end
