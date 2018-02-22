class WikiHistoriesController < ApplicationController
  load_and_authorize_resource :wiki
  load_and_authorize_resource :wiki_history, through: :wiki, shallow: true
  before_action :load_issue

  def show
    @wiki = @wiki_history.wiki
    @wiki_histories = paging(@wiki.wiki_histories.order(created_at: :desc))
  end

  private

  def paging(histories)
    histories.page(params[:page]).per(5)
  end

  def load_issue
    @issue = @wiki.post.issue if @wiki.present?
    @issue ||= @wiki_history.wiki.post.issue if @wiki_history.present?
  end

  def fixed_history_back_url_in_mobile_app
    if action_name == 'show'
      histories_wiki_post_path(@wiki.post)
    end
  end

end
