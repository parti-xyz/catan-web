module ApiEntityHelper
  ActionView::Base.send :include, Rails.application.routes.url_helpers
  def view_helpers
    ApplicationController.helpers
  end
end
