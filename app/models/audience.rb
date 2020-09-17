class Audience < ApplicationRecord
  belongs_to :announcement, counter_cache: true
  belongs_to :member

  counter_culture :announcement, column_name: proc {|model| model.noticed? ? 'noticed_audiences_count' : nil }

  scope :noticed, -> { where.not(noticed_at: nil) }
  scope :need_to_notice, -> { where(noticed_at: nil) }

  def noticed?
    noticed_at.present?
  end
end
