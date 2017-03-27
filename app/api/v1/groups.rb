module V1
  class Groups < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :groups do

      desc '내가 가입한 빠띠의 그룹 목록을 반환합니다'
      oauth2
      get :joined do
        present Group.nested_joined_by(resource_owner), base_options
      end

      desc '각 그룹에 속한 빠띠목록을 반환합니다'
      oauth2
      params do
        requires :slug, type: String, desc: '그룹의 slug'
      end
      get ':slug/parties' do
        group = Group.find_by_slug(params[:slug])
        present Issue.only_group(group).recent_touched, base_options
      end
    end
  end
end
