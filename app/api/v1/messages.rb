module V1
  class Messages < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :messages do
    end
  end
end
