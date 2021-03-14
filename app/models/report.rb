class Report < ApplicationRecord
  belongs_to :reportable, polymorphic: true
  belongs_to :user

  extend Enumerize
  enumerize :reason, in: %i(calumny vulgarism etc), default: :calumny, scope: true

  scope :recent, -> { order(created_at: :desc) }
end
