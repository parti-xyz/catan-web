class Label < ApplicationRecord
  has_many :posts, dependent: :nullify
  belongs_to :issue, counter_cache: true

  validates :title, presence: true, uniqueness: {scope: :issue_id}
  validates :issue, presence: true
end