module DefaultHelpers
  def logger
    Rails.logger
  end

  def permitted(params, require)
    ActionController::Parameters.new(declared(params, include_missing: false)).require(require).permit!
  end

  def base_options
    return {current_user: resource_owner}
  end

  def current_user
    resource_owner
  end
end
