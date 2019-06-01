module DefaultHelpers
  def logger
    Rails.logger
  end

  def permitted(params, require)
    ActionController::Parameters.new(declared(params, include_missing: false)).require(require).permit!
  end

  def current_user
    resource_owner
    # User.find_by(id: 19)
  end

  def present_authed(*args)
    options = args.count > 1 ? args.extract_options! : {}
    options[:current_user] = current_user if current_user.present?
    present *args, options
  end
end
