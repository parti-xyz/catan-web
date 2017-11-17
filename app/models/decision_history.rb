class DecisionHistory < ActiveRecord::Base
  belongs_to :post
  belongs_to :user

  scope :recent, -> { order(created_at: :desc).order(id: :desc) }

  def previous_of_current_post
    @previous ||= post.decision_histories.recent.where('created_at < ?', self.created_at).where('id < ?', self.id).first
  end

  def diff_body
    previous_text_body = ActionView::Base.full_sanitizer.sanitize previous_of_current_post.try(:body).try(:strip) || ""
    current_text_body = ActionView::Base.full_sanitizer.sanitize body.try(:strip) || ""

    Diffy::Diff.new(previous_text_body, current_text_body).to_s(:html)
  end
end
