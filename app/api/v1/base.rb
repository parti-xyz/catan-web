module V1
  class Base < Grape::API
    mount V1::Posts
    mount V1::DeviceTokens
  end
end
