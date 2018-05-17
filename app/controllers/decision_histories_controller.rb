class DecisionHistoriesController < ApplicationController
  load_and_authorize_resource :decision_history
  before_action :load_issue

  def show
    @post = @decision_history.post
    @decision_histories = paging(@post.decision_histories.order(created_at: :desc))
  end

  private

  def paging(histories)
    histories.page(params[:page]).per(5)
  end

  def load_issue
    @issue ||= @decision_history.post.issue if @decision_history.present?
  end
end
