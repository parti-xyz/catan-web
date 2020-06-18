
class Users::ConfirmationsController < Devise::ConfirmationsController
  include FrontableView

  def show
    super do
      sign_in(resource) if resource.errors.empty?
    end
  end

  protected

  def after_confirmation_path_for(resource_name, resource)
    if resource.is_a?(User) && resource.confirmation_group_slug.present?
      group = Group.find_by_slug(resource.confirmation_group_slug)

      if helpers.implict_front_namespace? && group.present?
        return new_front_member_request_url(subdomain: group.subdomain)
      end
    end

    root_path
  end
end