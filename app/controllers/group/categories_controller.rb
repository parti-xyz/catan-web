class Group::CategoriesController < Group::BaseController
  load_and_authorize_resource
  before_action :only_organizer

  def index
  end

  def create
    @category.group_slug = current_group.slug
    if @category.save
      flash[:notice] = t('activerecord.successful.messages.created')
    else
      errors_to_flash(@category)
    end

    if helpers.explict_front_namespace?
      turbolinks_redirect_to edit_current_group_front_categories_path
    else
      redirect_to group_categories_path
    end
  end

  def edit
  end

  def update
    if @category.update_attributes(category_params)
      flash[:notice] = t('activerecord.successful.messages.created')
    else
      errors_to_flash(@category)
    end

    if helpers.explict_front_namespace?
      turbolinks_redirect_to edit_current_group_front_categories_path
    else
      redirect_to group_categories_path
    end
  end

  def destroy
    if @category.destroy
      flash[:notice] = t('activerecord.successful.messages.deleted')
    else
      errors_to_flash(@category)
    end

    if helpers.explict_front_namespace?
      turbolinks_redirect_to edit_current_group_front_categories_path
    else
      redirect_to group_categories_path
    end
  end

  private

  def category_params
    params.require(:category).permit(:name)
  end
end
