Rails.application.routes.draw do
  class IndieGroupRouteConstraint
    include GroupHelper
    def matches?(request)
      fetch_group(request).blank?
    end
  end

  use_doorkeeper
  mount API, at: '/'

  post 'redactor2_rails/files', to: redirect('/')
  mount Redactor2Rails::Engine => '/redactor2_rails'
  devise_for :users, controllers: { registrations: 'users/registrations', omniauth_callbacks: 'users/omniauth_callbacks' }

  ## 그룹

  # 시민의회 그룹은 모두 role빠띠로 리다이렉트됩니다
  constraints(subdomain: 'citizensassembly') do
    get '/posts/:id', to: redirect(subdomain: '', path: '/posts/%{id}')
    get '/', to: redirect(subdomain: '', path: '/p/role')
    match '*path', to: redirect(subdomain: '', path: '/p/role'), via: :all
  end

  # 덕업넷 그룹은 일반 빠띠로 리다이렉트됩니다
  constraints(subdomain: 'duckup') do
    get '/p/:slug/*path', to: redirect(subdomain: '', path: '/p/%{slug}/%{path}')
    get '/', to: redirect(subdomain: '')
    match '*path', to: redirect(subdomain: nil, path: '%{path}'), via: :all
  end

  constraints(IndieGroupRouteConstraint.new) do
    authenticated :user do
      root 'dashboard#index', as: :dashboard_root
    end
  end
  root 'issues#home'
  get '/g/:group_slug/:parti_slug', to: redirect('https://%{group_slug}.parti.xyz/p/%{parti_slug}')
  get '/robots.:format', to: 'pages#robots'
  get 'parties/new_intro', to: 'issues#new_intro'

  resources :users, except: :show do
    collection do
      post 'toggle_root_page'
      get 'access_token'
      get 'pre_sign_up'
      get 'email_sign_in'
    end
  end
  unless Rails.env.production?
    get 'kill_me', to: 'users#kill_me'
  end

  # 통합 빠띠
  get '/p/:slug/', to: redirect { |params, req| "/p/#{MergedIssue.find_by(source_slug: params[:slug]).issue.slug}"}, constraints: lambda { |request, params|
    MergedIssue.exists?(source_slug: params[:slug])
  }
  get '/p/:slug/*path', to: redirect { |params, req|
    merged_issue = MergedIssue.find_by(source_slug: params[:slug])
    "/p/#{merged_issue.issue.slug}/#{params[:path]}"
  }, constraints: lambda { |request, params|
    MergedIssue.exists?(source_slug: params[:slug])
  }

  # 구 talk/opinion/note/article 주소를 신 post로 이동
  get 'talks/:id', to: 'redirects#talk'
  get 'opinions/:id', to: 'redirects#opinion'
  get 'notes/*path', to: redirect('https://parti.xyz')
  get 'articles/*path', to: redirect('https://parti.xyz')

  resources :groups
  resources :parties, as: :issues, controller: 'issues' do
    member do
      delete :remove_logo
      delete :remove_cover
    end
    collection do
      get :exist
      get :search_by_tags
      get :simple_search
      post :merge
    end
    resources :members do
      put :organizer, on: :collection
      delete :organizer, on: :collection
      delete :cancel, on: :collection
      delete :ban, on: :collection
    end
    resources :member_requests do
      post :accept, on: :collection
      delete :reject, on: :collection
    end
  end

  concern :upvotable do
    resources :upvotes do
      delete :cancel, on: :collection
    end
  end

  resources :posts, concerns: :upvotable do
    shallow do
      resources :comments, concerns: :upvotable
      resources :votes
    end
    member do
      get 'poll_social_card'
      get 'survey_social_card'
      get 'modal'
      post 'pin'
      delete 'unpin'
      get 'readers'
      get 'unreaders'
    end
  end
  post 'feedbacks', to: 'feedbacks#create'
  resources :options

  resources :references
  resources :polls do
    shallow do
      resources :votings
    end
  end
  get 'polls_or_surveys', to: 'polls_or_surveys#index'

  resources :relateds
  resources :messages
  resources :invitations

  namespace :group do
    resources :members do
      collection do
        put :organizer
        delete :organizer
        delete :ban
        delete :cancel
        post :admit
        get :new_admit
      end
    end
    resources :member_requests do
      post :accept, on: :collection
      delete :reject, on: :collection
    end
  end

  get 'file_source/:id/download', to: "file_sources#download", as: :download_file_source

  get '/dashboard', to: "dashboard#index", as: 'dashboard'
  get '/dashboard/intro', to: "dashboard#intro", as: 'dashboard_intro'
  get '/dashboard/new_posts_count', to: "dashboard#new_posts_count", as: 'new_dashboard_posts_count'

  get '/c/change2020', to: redirect(subdomain: 'change', path: '/'), constraints: { subdomain: '' }
  get '/c/vplatform', to: redirect(path: '/')

  %w(to-make-it-alive peacebridge gameisculture change-univeristy changebakkum-femi dignity wishforgoodjob politics21 wsc).each do |slug|
    get "/p/#{slug}", to: redirect(subdomain: 'change', path: "/p/#{slug}"), constraints: { subdomain: '' }
  end

  get "/p/innovators-declaration", to: redirect(subdomain: 'innovators', path: "/p/innovators-declaration"), constraints: { subdomain: '' }

  get '/p/:slug', to: "issues#slug_home", as: 'slug_issue'
  get '/p/:slug/references', to: "issues#slug_references", as: 'slug_issue_references'
  get '/p/:slug/polls', to: redirect('/p/%{slug}/polls_or_surveys')
  get '/p/:slug/polls_or_surveys', to: "issues#slug_polls_or_surveys", as: 'slug_issue_polls_or_surveys'
  get '/p/:slug/users', to: "issues#slug_users", as: 'slug_issue_users'
  get '/p/:slug/new_posts_count', to: "issues#new_posts_count", as: 'new_issue_posts_count'

  get '/u/:slug', to: "users#parties", as: 'slug_user'
  get '/u/:slug/posts', to: "users#posts", as: 'slug_user_posts'

  get '/welcome', to: "pages#welcome", as: 'welcome'
  get '/about', to: "pages#about", as: 'about'
  get '/privacy', to: "pages#privacy", as: 'privacy'
  get '/terms', to: "pages#terms", as: 'terms'
  if Rails.env.development?
    get '/score', to: "pages#score"
    get '/analyze', to: "pages#analyze"
  end

  get '/tags/:name', to: "tags#show", as: :tag
  get '/categories/:slug', to: "categories#show", as: :category

  authenticate :user, lambda { |u| u.admin? } do
    get '/test/summary', to: "users#summary_test"
  end

  get '/dev/components', to: 'pages#components'

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/devel/emails"
  end

  namespace :admin do
    root to: 'monitors#index'
    resources :issues do
      post 'merge', on: :collection
      post 'freeze', on: :collection
    end

    resources :roles do
      collection do
        post :add
        delete :remove
      end
    end
    resources :users do
      collection do
        get 'all_email'
      end
    end
    resources :groups
    resources :blinds
  end
end
