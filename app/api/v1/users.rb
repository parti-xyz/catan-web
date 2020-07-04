module V1
  class Users < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :users do
      desc '현재 로그인한 계정의 정보를 반환합니다.'
      oauth2
      get 'current_user' do
        entity = Class.new(User::Entity)
        entity.expose :important_not_mention_messages_count, as: :new_messages_count
        entity.expose :important_mention_messages_count, as: :new_mentions_count
        present resource_owner, with: entity
      end
    end
  end
end
