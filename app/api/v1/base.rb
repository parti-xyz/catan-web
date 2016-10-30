module V1
  class Base < Grape::API
    mount V1::Users
    mount V1::Dashboard
    mount V1::Comments
  end
end
