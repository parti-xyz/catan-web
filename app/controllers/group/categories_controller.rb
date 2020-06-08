class Group::CategoriesController < Group::BaseController
  load_and_authorize_resource
  before_action :only_organizer

  def index
  end

  def create
    @category.group_slug = current_group.slug
    unless @category.save
      errors_to_flash(@category)
    end

    redirect_to group_categories_path
  end

  def edit
  end

  def update
    unless @category.update_attributes(category_params)
      errors_to_flash(@category)
    end

    redirect_to group_categories_path
  end

  def destroy
    unless @category.destroy
      errors_to_flash(@category)
    end

    redirect_to group_categories_path
  end

  private

  def category_params
    params.require(:category).permit(:name)
  end
end
