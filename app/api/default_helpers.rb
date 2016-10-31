module DefaultHelpers
  def logger
    Rails.logger
  end

  def permitted(params, require)
    ActionController::Parameters.new(declared(params)).require(require).permit!
  end

  def authorize!(*args)
    ::Ability.new(resource_owner).authorize!(*args)
  end
end
