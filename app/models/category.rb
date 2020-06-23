class Category < ApplicationRecord
  include Grape::Entity::DSL
  entity do
    expose :name, :id
  end

  belongs_to :group, foreign_key: :group_slug, primary_key: :slug
  has_many :issues, dependent: :nullify

  scope :sort_by_name, -> { order(Arel.sql("if(ascii(substring(categories.name, 1)) < 128, 1, 0)")).order('categories.name').order(:id) }

  scope :sort_by_default, -> { order(position: :asc).order(Arel.sql("if(ascii(substring(categories.name, 1)) < 128, 1, 0)")).order('categories.name').order(:id) }
  validates :name, uniqueness: { scope: :group_slug }, presence: true

  NADA_ID = 0

  def self.default_compare_values(category)
    if category.present?
      [category.position.presence || Float::INFINITY, (category.name.codepoints[0] < 128 ? 1 : 0), category.name, category.id]
    else
      [Float::INFINITY, Float::INFINITY, "", -1]
    end
  end
end
