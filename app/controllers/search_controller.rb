class SearchController < ApplicationController
  def index
    @results = (params[:q].blank? ? Search.none : Search.search_for(params[:q])).page(params[:page])
  end
end

