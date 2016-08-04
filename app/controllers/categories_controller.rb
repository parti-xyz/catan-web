class CategoriesController < ApplicationController
  def show
    @category = current_group.find_category_by_slug(params[:slug])
    @issues = Issue.in_group(current_group).categorized_with(params[:slug]).hottest
  end
end
