module V1
  class Users < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :users do
      desc '내 정보를 가져옵니다'
      oauth2
      get :me do
        present :user, resource_owner
      end

      desc '닉네임에 해당되는 사용자의 정보를 반환합니다'
      params do
        requires :nickname, type: String
      end
      get :by_nickname do
        present :user, User.find_by(nickname: params[:nickname])
      end

      desc '슬러그에 해당되는 사용자의 정보를 반환합니다'
      params do
        requires :slug, type: String
      end
      get :by_slug do
        id = User.slug_to_id(params[:slug])
        present(:user, User.find(id)) and return if id.present?
        present :user, User.find_by!(nickname: params[:slug].try(:downcase))
      end
    end
  end
end
