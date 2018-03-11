class Admin::GroupsController < Admin::BaseController
  def index
    @groups = Group.where.not(slug: 'indie').sort_by_name.page(params[:page])
  end
end
