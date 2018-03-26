if defined?(Remotipart)

  module Remotipart
    module EscapeJavascriptFix

      def escape_javascript(javascript)
        if remotipart_submitted?
          super("#{javascript}")
        else
          super
        end
      end

      alias_method :j, :escape_javascript

    end
  end

  ActiveSupport.on_load :action_view do
    ActionView::Base.send(:include, Remotipart::EscapeJavascriptFix)
  end

end
