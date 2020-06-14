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

    if helpers.explict_front_namespace?
      flash[:notice] = t('activerecord.successful.messages.created')
      redirect_to edit_current_group_front_categories_path, trubolinks: true
    else
      redirect_to group_categories_path
    end
  end

  def edit
  end

  def update
    unless @category.update_attributes(category_params)
      errors_to_flash(@category)
    end

    if helpers.explict_front_namespace?
      flash[:notice] = t('activerecord.successful.messages.created')
      redirect_to edit_current_group_front_categories_path, trubolinks: true
    else
      redirect_to group_categories_path
    end
  end

  def destroy
    unless @category.destroy
      errors_to_flash(@category)
    end

    if helpers.explict_front_namespace?
      flash[:notice] = t('activerecord.successful.messages.deleted')
      redirect_to edit_current_group_front_categories_path, trubolinks: true
    else
      redirect_to group_categories_path
    end
  end

  private

  def category_params
    params.require(:category).permit(:name)
  end
end
