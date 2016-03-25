Rails.application.routes.draw do
  mount Redactor2Rails::Engine => '/redactor2_rails'

  devise_for :users, controllers: { registrations: 'users/registrations', omniauth_callbacks: 'users/omniauth_callbacks' }
  #sso_devise

  root 'pages#home'

  resources :users, except: :show

  resources :issues do
    member do
      get :users
      get :campaign
    end
    collection do
      get :exist
    end
    resources :watches do
      delete :cancel, on: :collection
    end
  end

  resources :posts, only: [] do
    shallow do
      resources :comments do
        resources :upvotes do
          delete :cancel, on: :collection
        end
      end
      resources :votes
      resources :likes do
        delete :cancel, on: :collection
      end
    end
  end

  resources :articles
  resources :opinions do
    get 'social_card', on: :member
  end
  resources :questions do
    resources :answers, shallow: true
  end
  resources :discussions do
    resources :proposals, shallow: true
  end
  resources :talks
  resources :relateds

  get '/dashboard', to: "dashboard#index", as: 'dashboard'
  get '/dashboard/posts', to: "dashboard#posts", as: 'dashboard_posts'
  get '/dashboard/comments', to: "dashboard#comments", as: 'dashboard_comments'
  get '/dashboard/campaign', to: "dashboard#campaign", as: 'dashboard_campaign'

  get '/welcome', to: "pages#welcome", as: 'welcome'
  get '/about', to: "pages#about", as: 'about'
  get '/i/:slug', to: "issues#slug", as: 'slug_issue'
  get '/i/:slug/posts', to: "issues#slug_posts", as: 'slug_issue_posts'
  get '/i/:slug/comments', to: "issues#slug_comments", as: 'slug_issue_comments'
  get '/i/:slug/campaign', to: "issues#slug_campaign", as: 'slug_issue_campaign'
  get '/u/:nickname', to: "users#gallery", as: 'nickname_user'
  get '/u/:nickname/posts', to: "users#posts", as: 'nickname_user_posts'
  get '/u/:nickname/comments', to: "users#comments", as: 'nickname_user_comments'
  get '/tags/:name', to: "tags#show", as: 'show_tag'
  authenticate :user, lambda { |u| u.admin? } do
    get '/test/summary', to: "users#summary_test"
  end
  get "transfers/start", as: "start_transfers"
  post "transfers/confirm", as: "confirm_transfers"
  get "transfers/final", as: "final_transfers"

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/devel/emails"
  end
end
