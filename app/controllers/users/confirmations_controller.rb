
class Users::ConfirmationsController < Devise::ConfirmationsController
  include FrontableView

  protected

  def after_confirmation_path_for(resource_name, resource)
    if resource.is_a?(User) && resource.confirmation_group_slug.present?
      group = Group.find_by_slug(resource.confirmation_group_slug)

      if helpers.implict_front_namespace?
        return email_sign_in_front_users_url(subdomain: group&.subdomain)
      else
        return email_sign_in_users_url(subdomain: group&.subdomain)
      end
    end

    root_path
  end
end