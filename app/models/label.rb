class Label < ApplicationRecord
  has_many :posts, dependent: :nullify
  # belongs_to :issue, counter_cache: true
  belongs_to :group, counter_cache: true

  validates :title, presence: true, uniqueness: {scope: :group_id}
  validates :group, presence: true
end