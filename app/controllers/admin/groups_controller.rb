class Admin::GroupsController < Admin::BaseController
  def index
    @groups = Group.where.not(slug: 'indie').sort_by_name.page(params[:page])
  end

  def destroy
    @group = Group.find_by(id: params[:id])
    render_404 and return  if @group.blank?

    if @group.destroy
      flash[:success] = I18n.t('activerecord.successful.messages.deleted')
    else
      errors_to_flash @group
    end
    redirect_to admin_groups_path
  end
end
