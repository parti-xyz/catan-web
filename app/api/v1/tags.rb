module V1
  class Tags < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :tags do
      desc '빠띠에서 많이 쓰이는 태그를 반환합니다.'
      params do
        requires :limit, type: Integer
      end
      get :most_used_on_parties do
        present Issue.most_used_tags(params[:limit]).map(&:name)
      end
    end
  end
end
