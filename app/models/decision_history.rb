class DecisionHistory < ActiveRecord::Base
  belongs_to :post
  belongs_to :user

  include Historyable
  def sibling_histories
    post.decision_histories
  end

  def diffable_body
    ActionController::Base.helpers.simple_format(body)
  end

  def touched_body?
    previous_of_current_post.present?
  end

  def previous_of_current_post
    @previous ||= post.decision_histories.recent.where('created_at < ?', self.created_at).where('id < ?', self.id).first
  end
end
