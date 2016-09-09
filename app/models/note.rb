class Note < ActiveRecord::Base
  MAX_BODY_LENGTH = 250

  include Postable
  acts_as_paranoid
  acts_as :post, as: :postable

  validates :body, presence: true
  validate :check_body_length

  scope :recent, -> { order(created_at: :desc) }
  scope :latest, -> { after(1.day.ago) }
  scope :previous_of_recent, ->(note) {
    base = recent
    base = base.where('notes.created_at < ?', note.created_at) if note.present?
    base
  }

  def title
    body
  end

  def commenters
    comments.map(&:user).uniq.reject { |u| u == self.user }
  end

  def specific_origin
    self
  end

  private

  def check_body_length
    if self.body != nil
      if self.body.gsub(/\r\n/, ' ').length > Note::MAX_BODY_LENGTH
        errors.add(:body, I18n.t('activerecord.errors.models.note.attributes.body.too_long'))
      end
    end
  end
end
