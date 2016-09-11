class API < Grape::API
  prefix "api"
  version ['v1'], using: :path
  mount V1::Base
end
