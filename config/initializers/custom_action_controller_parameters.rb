ActiveSupport.on_load :action_controller do
  ActionController::Parameters.class_eval {
    define_method :any? do
      !empty?
    end
  }
end
