class API < Grape::API
  prefix "api"
  version ['v1'], using: :path
  use ::WineBouncer::OAuth2
  authorize_routes!

  mount V1::Base
end
