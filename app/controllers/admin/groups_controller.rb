class Admin::GroupsController < Admin::BaseController
  def index
    @groups = Group.where.not(slug: 'indie').page(params[:page])
  end
end
