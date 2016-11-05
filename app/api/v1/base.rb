module V1
  class Base < Grape::API
    mount V1::Users
    mount V1::Dashboard
    mount V1::Comments
    mount V1::Upvotes
    mount V1::Votings
    mount V1::Parties
    mount V1::Messages
  end
end
