class Mention < ApplicationRecord
  belongs_to :user
  belongs_to :mentionable, polymorphic: true

  validates :user, uniqueness: {scope: [:mentionable]}
end
