Rails.application.routes.draw do
  class RootPartiRouteConstraint
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

  constraints(RootPartiRouteConstraint.new) do
    authenticated :user do
      root 'dashboard#index', as: :dashboard_root
    end
  end
  root 'pages#home'
  get '/g/:group_slug/:parti_slug', to: redirect('http://%{group_slug}.parti.xyz/p/%{parti_slug}')

  get '/home', to: 'pages#home'
  get '/robots.:format', to: 'pages#robots'
  get 'parties/new_intro', to: 'issues#new_intro'

  resources :users, except: :show do
    post 'toggle_root_page', on: :collection
    get 'access_token', on: :collection
  end
  unless Rails.env.production?
    get 'kill_me', to: 'users#kill_me'
  end

  class MergedIssueConstraint
    def matches?(request)
      fetch_group(request).blank?
    end
  end

  get '/p/:slug/', to: redirect { |params, req| "/p/#{MergedIssue.find_by(source_slug: params[:slug]).issue.slug}"}, constraints: lambda { |request, params|
    MergedIssue.exists?(source_slug: params[:slug])
  }
  get '/p/:slug/*path', to: redirect { |params, req|
    merged_issue = MergedIssue.find_by(source_slug: params[:slug])
    "/p/#{merged_issue.issue.slug}/#{params[:path]}"
  }, constraints: lambda { |request, params|
    MergedIssue.exists?(source_slug: params[:slug])
  }

  resources :parties, as: :issues, controller: 'issues' do
    member do
      delete :remove_logo
      delete :remove_cover
    end
    collection do
      get :exist
      get :search
      get :search_by_tags
      post :merge
    end
    resources :members do
      delete :cancel, on: :collection
    end
    resources :sections, shallow: true
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
    get 'poll_social_card', on: :member
  end

  resources :references
  resources :polls do
    shallow do
      resources :votings
    end
  end

  resources :relateds
  resources :messages
  resources :wikis do
    resources :wiki_histories, path: :histories, shallow: true
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

  get '/p/:slug', to: "issues#slug_home", as: 'slug_issue'
  get '/p/:slug/references', to: "issues#slug_references", as: 'slug_issue_references'
  get '/p/:slug/polls', to: "issues#slug_polls", as: 'slug_issue_polls'
  get '/p/:slug/wikis', to: "issues#slug_wikis", as: 'slug_issue_wikis'
  get '/p/:slug/users', to: "issues#slug_users", as: 'slug_issue_users'
  get '/p/:slug/new_posts_count', to: "issues#new_posts_count", as: 'new_issue_posts_count'

  get '/u/:slug', to: "users#parties", as: 'slug_user'
  get '/u/:slug/polls', to: "users#polls", as: 'slug_user_polls'

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
    end

    resources :users do
      collection do
        get 'all_email'
      end
    end
    resources :blinds
  end
end
