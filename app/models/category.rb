class Category < ApplicationRecord
  include Grape::Entity::DSL
  entity do
    expose :name, :id
  end

  belongs_to :group, foreign_key: :group_slug, primary_key: :slug
  has_many :issues, dependent: :nullify

  scope :sort_by_name, -> { order(Arel.sql("if(ascii(substring(categories.name, 1)) < 128, 1, 0)")).order('categories.name') }
  validates :name, uniqueness: { scope: :group_slug }, presence: true

  NADA_ID = 0
end
