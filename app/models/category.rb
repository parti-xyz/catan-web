class Category < ActiveRecord::Base
  belongs_to :group, foreign_key: :group_slug, primary_key: :slug
  has_many :issues, dependent: :nullify

  validates :name, uniqueness: { scope: :group_slug }, presence: true
end
