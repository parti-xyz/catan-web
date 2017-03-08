class CategoriesController < ApplicationController
  def show
    render_404 and return if current_group.blank?
    @category = current_group.find_category_by_slug(params[:slug])
    @issues = Issue.only_group(current_group).categorized_with(params[:slug]).hottest
  end
end
