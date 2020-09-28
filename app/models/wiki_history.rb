class WikiHistory < ApplicationRecord
  belongs_to :user
  belongs_to :wiki
  has_many :comments, dependent: :nullify

  scope :significant, -> { where.not(code: TOUCH_BODY_CODES).or(WikiHistory.where(trivial_update_body: false)) }

  TOUCH_BODY_CODES = %w[update_body update_title_and_body]

  include Historyable
  def sibling_histories
    wiki.wiki_histories
  end

  def diffable_body
    body
  end

  def activity
    user_word = if user.present?
      if block_given?
        yield user
      else
        "@#{user.nickname}님이"
      end
    else
      I18n.t("views.user.anonymous")
    end

    I18n.t("views.wiki.history.#{code}", default: nil, user_word: user_word)
  end

  def trivial?
    touched_body? && trivial_update_body?
  end

  def touched_body?
    TOUCH_BODY_CODES.include? code
  end

  def touched_title?
    %w(update_title update_title_and_body).include? code
  end
end
