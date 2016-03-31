class Mention < ActiveRecord::Base
  belongs_to :user
  belongs_to :mentionable, polymorphic: true

  validates :user, uniqueness: {scope: [:mentionable]}
end
