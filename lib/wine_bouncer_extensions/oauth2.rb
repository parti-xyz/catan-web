module WineBouncerExtensions
  class OAuth2 < Grape::Middleware::Base

    #monkeypatch protection behavior. This method shares the given token with the endpoints even if they aren't protected.
    def before
      abort 'doorkeeper_authorize'
      set_auth_strategy(WineBouncer.configuration.auth_strategy)
      auth_strategy.api_context = context
      #extend the context with auth methods.
      context.extend(WineBouncer::AuthMethods)
      context.protected_endpoint = endpoint_protected?
      self.doorkeeper_request= env # set request for later use.
      if context.protected_endpoint? or valid_doorkeeper_token?(*scopes)
        doorkeeper_authorize!(*auth_scopes)
      end
      context.doorkeeper_access_token = doorkeeper_token
    end
  end
end
