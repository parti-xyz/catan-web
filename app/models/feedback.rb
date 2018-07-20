class Feedback < ApplicationRecord
  belongs_to :user
  belongs_to :survey, counter_cache: true
  belongs_to :option, counter_cache: true
  validates :user, uniqueness: { scope: :option_id }, presence: true
end
