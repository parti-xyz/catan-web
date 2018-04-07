class Admin::MonitorsController < Admin::BaseController
  def index
    @statistics = Statistics.recent.limit(100)
  end
end
