module V1
  class Base < Grape::API
    mount V1::Posts
    mount V1::FileSources
    mount V1::DeviceTokens
    mount V1::Groups
  end
end
