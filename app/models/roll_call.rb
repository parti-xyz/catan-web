class RollCall < ApplicationRecord
  belongs_to :user
  belongs_to :event
  belongs_to :inviter, class_name: 'User', optional: true

  extend Enumerize
  enumerize :status, in: [:attend, :absent, :invite, :to_be_decided], predicates: true, scope: true
end
