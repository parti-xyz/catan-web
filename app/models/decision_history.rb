class DecisionHistory < ApplicationRecord
  belongs_to :post
  belongs_to :user, optional: true

  include Historyable
  def sibling_histories
    post.decision_histories
  end

  def diffable_body
    body
  end

  def touched_body?
    previous_of_current_post.present?
  end

  def previous_of_current_post
    @previous ||= post.decision_histories.recent.where('created_at < ?', self.created_at).where('id < ?', self.id).first
  end
end
