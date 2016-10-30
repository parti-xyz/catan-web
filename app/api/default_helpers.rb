module DefaultHelpers
  def logger
    Rails.logger
  end

  def permitted(params, require)
    ActionController::Parameters.new(declared(params)).require(require).permit!
  end
end
