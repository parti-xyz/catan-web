module Admin
  class ReportsController < Admin::BaseController
    def index
      @reports = Report.all.recent.page(params[:page]).load
    end
  end
end
