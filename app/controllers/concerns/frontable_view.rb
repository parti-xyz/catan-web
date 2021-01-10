module FrontableView
  extend ActiveSupport::Concern

  included do
    layout :frontable_layout
    before_action :frontable_view_path
  end

  def frontable_view_path
    prepend_view_path Rails.root.join('app/views/front').to_s if front_devise?
  end

  def frontable_layout
    'front/simple' if front_devise?
  end

  private

  def front_devise?
    helpers.implict_front_namespace? || current_group.blank?
  end
end
