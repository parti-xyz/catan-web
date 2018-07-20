class WikiHistory < ApplicationRecord
  belongs_to :user
  belongs_to :wiki

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


  def touched_body?
    %w(update_body update_title_and_body).include? code
  end

  def touched_title?
    %w(update_title update_title_and_body).include? code
  end

end
