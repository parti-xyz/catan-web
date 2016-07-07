class Related < ActiveRecord::Base
  belongs_to :issue
  belongs_to :target, class_name: Issue

  validates :issue, presence: true
  validates :target, presence: true
  validates :issue, uniqueness: {scope: [:target]}
  validate :prevent_self_relation

  private

  def prevent_self_relation
    if self.issue == self.target
      errors.add(:target, I18n.t('activerecord.errors.models.related.attributes.target.self_relation'))
    end
  end
end
