
class Users::ConfirmationsController < Devise::ConfirmationsController
  include FrontableView

  def show
    super do
      sign_in(resource) if resource.errors.empty?
    end
  end

  protected

  def after_confirmation_path_for(resource_name, resource)
    return root_path if !resource.is_a?(User) || resource.touch_group_slug.blank?

    group = Group.find_by_slug(resource.touch_group_slug)
    return root_path if group.blank?

    return root_url(subdomain: group.subdomain) if group.member?(resource) || !group.frontable?

    return new_front_member_request_url(subdomain: group.subdomain)
  end
end