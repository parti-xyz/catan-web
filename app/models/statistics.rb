class Statistics < ActiveRecord::Base
  scope :recent, -> { order(when: :desc) }
end
