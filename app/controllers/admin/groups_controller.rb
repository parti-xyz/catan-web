class Admin::GroupsController < AdminController
  load_and_authorize_resource

  def index
    @group = params[:id].present? ? Group.find(params[:id]) : Group.new
    @groups = Group.all
  end

  def create
    @group.user = current_user
    errors_to_flash(@group) unless @group.save
    redirect_to admin_groups_path
  end

  def update
    errors_to_flash(@group) unless @group.update_attributes(group_params)
    redirect_to admin_groups_path
  end

  def destroy
    errors_to_flash(@group) unless @group.destroy
    redirect_to admin_groups_path
  end

  private

  def group_params
    params.require(:group).permit(:slug, :name, :logo, :categories, :site_title, :head_title, :site_description, :site_keywords)
  end
end
