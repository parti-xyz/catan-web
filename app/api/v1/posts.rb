module V1
  class Posts < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :posts do
      desc '특정 글에 대한 정보를 반환합니다'
      oauth2
      params do
        requires :id, type: Integer, desc: '글 번호'
      end
      get ':id' do
        @post = Post.find_by!(id: params[:id])
        present :post, @post
      end
    end
  end
end
