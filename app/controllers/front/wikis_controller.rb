class Front::WikisController < Front::BaseController
  def card
    @current_wiki = Wiki.with_deleted
      .includes(:issue, :post )
      .find(params[:id])

    render layout: nil
  end
end