class API < Grape::API
  prefix "api"
  version ['v1'], using: :path
  use ::WineBouncer::OAuth2
  mount V1::Base
end
