Rails.application.routes.draw do
  class GroupConstraint
    # Implement the .matches? method and pass in the request object
    def self.matches? request
      matching_site?(request)
    end

    def self.matching_site? request
      Group.exists_slug? request.subdomain
    end
  end
  match '/', :to => 'groups#index', :constraints => GroupConstraint, via: :all

  post 'redactor2_rails/files', to: redirect('/')
  mount Redactor2Rails::Engine => '/redactor2_rails'
  devise_for :users, controllers: { registrations: 'users/registrations', omniauth_callbacks: 'users/omniauth_callbacks' }

  root 'pages#home'

  get '/robots.:format' => 'pages#robots'

  resources :users, except: :show
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
    end
    resources :watches do
      delete :cancel, on: :collection
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
  end

  resources :articles do
    get 'partial', on: :member
  end
  resources :opinions do
    get 'social_card', on: :member
  end
  resources :talks
  resources :notes
  resources :relateds
  resources :messages
  resources :wikis do
    resources :wiki_histories, path: :histories, shallow: true
  end

  get 'file_source/:id/download', to: "file_sources#download", as: :download_file_source

  get '/dashboard', to: "dashboard#index", as: 'dashboard'
  get '/dashboard/articles', to: "dashboard#articles", as: 'dashboard_articles'
  get '/dashboard/opinions', to: "dashboard#opinions", as: 'dashboard_opinions'
  get '/dashboard/talks', to: "dashboard#talks", as: 'dashboard_talks'
  get '/dashboard/parties', to: "dashboard#parties", as: 'dashboard_parties'
  get '/dashboard/new_comments_count', to: "dashboard#new_comments_count", as: 'new_dashboard_comments_count'

  get '/c/:slug', to: "campaigns#slug_show", as: 'slug_campaign'

  get '/p/:slug', to: "issues#slug_home", as: 'slug_issue'
  get '/p/:slug/articles', to: "issues#slug_articles", as: 'slug_issue_articles'
  get '/p/:slug/opinions', to: "issues#slug_opinions", as: 'slug_issue_opinions'
  get '/p/:slug/talks', to: "issues#slug_talks", as: 'slug_issue_talks'
  get '/p/:slug/notes', to: "issues#slug_notes", as: 'slug_issue_notes'
  get '/p/:slug/wikis', to: "issues#slug_wikis", as: 'slug_issue_wikis'
  get '/p/:slug/users', to: "issues#slug_users", as: 'slug_issue_users'
  get '/p/:slug/new_comments_count', to: "issues#new_comments_count", as: 'new_issue_comments_count'

  get '/u/:slug', to: "users#comments", as: 'slug_user'
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
