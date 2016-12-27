class Survey < ActiveRecord::Base
  has_many :options, dependent: :destroy
  accepts_nested_attributes_for :options, reject_if: proc { |attributes|
    attributes['body'].try(:strip).blank?
  }

  validate :has_options

  def has_options
    errors.add(:base, 'must add at least one options') if self.options.blank?
  end
end
