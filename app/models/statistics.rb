class Statistics < ApplicationRecord
  scope :recent, -> { order(when: :desc) }
end
