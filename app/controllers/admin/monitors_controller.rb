class Admin::MonitorsController < Admin::BaseController
  def index
    @statistics = Statistics.recent.limit(50)
  end
end
