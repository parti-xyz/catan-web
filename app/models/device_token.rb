class DeviceToken < ApplicationRecord
  belongs_to :user

  validates :user, uniqueness: { scope: :registration_id }, presence: true
  validates :registration_id, presence: true
end
