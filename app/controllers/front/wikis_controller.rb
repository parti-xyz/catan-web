class Front::WikisController < Front::BaseController
  def card
    @current_wiki = Wiki.with_deleted
      .includes(:issue, :post )
      .find(params[:id])

    render partial: 'front/wikis/card', locals: { current_wiki: @current_wiki }, layout: nil
  end
end