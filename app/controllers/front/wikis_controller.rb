class Front::WikisController < Front::BaseController
  def card
    @current_wiki = Wiki.includes(:issue, :post )
      .find(params[:id])
    render_403 and return if @current_wiki.post&.issue&.private_blocked?(current_user)

    render partial: 'front/wikis/card', locals: { current_wiki: @current_wiki }, layout: nil
  end
end