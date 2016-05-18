class Watch < ActiveRecord::Base
  belongs_to :user
  belongs_to :watchable, counter_cache: true, polymorphic: true

  validates :user, presence: true
  validates :watchable, presence: true
  validates :user, uniqueness: {scope: [:watchable_id, :watchable_type]}
end
