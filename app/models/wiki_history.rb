class WikiHistory < ActiveRecord::Base
  belongs_to :user
  belongs_to :wiki

  scope :recent, -> { order(created_at: :desc).order(id: :desc) }

  def activity
    user_text = if user.present?
      if block_given?
        yield user
      else
        "@#{user.nickname}"
      end
    else
      I18n.t("views.user.anonymous")
    end

    I18n.t("views.wiki.history.#{code}", default: nil, user: user_text)
  end

  def touched_body?
    %w(update_body update_title_and_body).include? code
  end

  def previous
    @previous ||= wiki.wiki_histories.recent.where('created_at < ?', self.created_at).where('id < ?', self.id).first
  end

  def diff_body
    return unless touched_body?

    previous_text_body = ActionView::Base.full_sanitizer.sanitize previous.body.try(:strip) || ""
    current_text_body = ActionView::Base.full_sanitizer.sanitize body.try(:strip) || ""

    Diffy::Diff.new(previous_text_body, current_text_body).to_s(:html)
  end
end
