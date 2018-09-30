class RollCall < ApplicationRecord
  belongs_to :user
  belongs_to :event

  extend Enumerize
  enumerize :status, in: [:attend, :absent, :invite, :to_be_decided], predicates: true, scope: true
end
