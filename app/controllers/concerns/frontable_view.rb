module FrontableView
  extend ActiveSupport::Concern

  included do
    layout :frontable_layout
    before_action :frontable_view_path
  end


  def frontable_view_path
    if helpers.implict_front_namespace?
      prepend_view_path Rails.root.join("app/views/front").to_s
    end
  end

  def frontable_layout
    if helpers.implict_front_namespace?
      'front/simple'
    end
  end
end