module V1
  class Base < Grape::API
    mount V1::Posts
    mount V1::FileSources
    mount V1::DeviceTokens
    mount V1::Groups
    mount V1::Messages
    mount V1::Users
    mount V1::Home
  end
end
