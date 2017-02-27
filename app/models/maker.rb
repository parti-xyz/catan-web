class Maker < ActiveRecord::Base
  belongs_to :user
  belongs_to :makable, polymorphic: true
  validates :user, uniqueness: {scope: [:makable_id, :makable_type]}
end
