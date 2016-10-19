Rails.application.routes.draw do
  use_doorkeeper
  mount API, at: '/'

  post 'redactor2_rails/files', to: redirect('/')
  mount Redactor2Rails::Engine => '/redactor2_rails'
  devise_for :users, controllers: { registrations: 'users/registrations', omniauth_callbacks: 'users/omniauth_callbacks' }

  authenticated :user do
    root 'dashboard#index', as: :dashboard_root
  end
  root 'pages#home'

  get '/home', to: 'pages#home'
  get '/robots.:format', to: 'pages#robots'
  get '/monitors', to: 'monitors#index'
  get 'parties/new_intro', to: 'issues#new_intro'

  resources :users, except: :show do
    post 'toggle_root_page', on: :collection
  end
  unless Rails.env.production?
    get 'kill_me', to: 'users#kill_me'
  end

  resources :campaigns
  resources :parties, as: :issues, controller: 'issues' do
    member do
      get :opinions
      delete :remove_logo
      delete :remove_cover
    end
    collection do
      get :exist
      get :search
      get :search_by_tags
    end
    resources :watches do
      delete :cancel, on: :collection
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
  end

  resources :articles do
    get 'partial', on: :member
    post 'recrawl', on: :member
  end
  resources :opinions do
    get 'social_card', on: :member
  end
  resources :talks
  resources :relateds
  resources :messages
  resources :wikis do
    resources :wiki_histories, path: :histories, shallow: true
  end

  get 'file_source/:id/download', to: "file_sources#download", as: :download_file_source

  get '/dashboard', to: "dashboard#index", as: 'dashboard'
  get '/dashboard/intro', to: "dashboard#intro", as: 'dashboard_intro'
  get '/dashboard/articles', to: "dashboard#articles", as: 'dashboard_articles'
  get '/dashboard/opinions', to: "dashboard#opinions", as: 'dashboard_opinions'
  get '/dashboard/talks', to: "dashboard#talks", as: 'dashboard_talks'
  get '/dashboard/parties', to: "dashboard#parties", as: 'dashboard_parties'
  get '/dashboard/new_posts_count', to: "dashboard#new_posts_count", as: 'new_dashboard_posts_count'

  get '/c/change2020', to: redirect(subdomain: 'change', path: '/'), constraints: { subdomain: '' }

  %w(to-make-it-alive peacebridge gameisculture change-univeristy changebakkum-femi dignity wishforgoodjob politics21 wsc).each do |slug|
    get "/p/#{slug}", to: redirect(subdomain: 'change', path: "/p/#{slug}"), constraints: { subdomain: '' }
  end


  get '/c/:slug', to: "campaigns#slug_show", as: 'slug_campaign'

  get '/p/:slug', to: "issues#slug_home", as: 'slug_issue'
  get '/p/:slug/articles', to: "issues#slug_articles", as: 'slug_issue_articles'
  get '/p/:slug/opinions', to: "issues#slug_opinions", as: 'slug_issue_opinions'
  get '/p/:slug/talks', to: "issues#slug_talks", as: 'slug_issue_talks'
  get '/p/:slug/talks/sections/:section_id', to: "issues#slug_talks", as: 'slug_issue_talks_with_section'
  get '/p/:slug/wikis', to: "issues#slug_wikis", as: 'slug_issue_wikis'
  get '/p/:slug/users', to: "issues#slug_users", as: 'slug_issue_users'
  get '/p/:slug/new_posts_count', to: "issues#new_posts_count", as: 'new_issue_posts_count'

  get '/u/:slug', to: "users#parties", as: 'slug_user'
  get '/u/:slug/comments', to: "users#comments", as: 'slug_user_comments'
  get '/u/:slug/upvotes', to: "users#upvotes", as: 'slug_user_upvotes'
  get '/u/:slug/votes', to: "users#votes", as: 'slug_user_votes'

  get '/welcome', to: "pages#welcome", as: 'welcome'
  get '/about', to: "pages#about", as: 'about'
  get '/privacy', to: "pages#privacy", as: 'privacy'
  get '/terms', to: "pages#terms", as: 'terms'
  if Rails.env.development?
    get '/stat', to: "pages#stat"
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
    root "featured_contents#index"
    resources :featured_contents
    resources :featured_issues
    resources :featured_campaigns
  end
end
