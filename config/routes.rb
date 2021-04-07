include GroupHelper
include MobileAppHelper

Rails.application.routes.draw do
  class NoGroupRouteConstraint
    def matches?(request)
      fetch_group(request).blank?
    end
  end

  class FrontGroupRouteConstraint
    def matches?(request)
      group = fetch_group(request)
      group.present? && group.frontable?
    end
  end

  mount Apple::App::Site::Association, at: '/'
  use_doorkeeper
  mount API, at: '/'

  post '/tinymce_assets' => 'tinymce_assets#create'
  post '/editor_assets' => 'editor_assets#create'

  devise_for :users, controllers: {
    registrations: 'users/registrations',
    omniauth_callbacks: 'users/omniauth_callbacks',
    passwords: 'users/passwords',
    sessions: 'users/sessions',
    confirmations: 'users/confirmations'
  }
  get 'after_sign_out', to: redirect { |path_params, request|
    if is_mobile_app_get_request?(request)
      Rails.application.routes.url_helpers.mobile_app_teardown_sessions_path(after_sign_out_path: request.params[:after_sign_out_path])
    else
      request.params[:after_sign_out_path]
    end
  }

  ## 그룹

  # 시민의회 그룹은 모두 role빠띠로 리다이렉트됩니다
  constraints(subdomain: 'citizensassembly') do
    get '/posts/:id', to: redirect(subdomain: '', path: '/posts/%{id}')
    get '/', to: redirect(subdomain: '', path: '/p/role')
    match '*path', to: redirect(subdomain: '', path: '/p/role'), via: :all
  end

  constraints(NoGroupRouteConstraint.new) do
    authenticated :user do
      root 'pages#dock'
    end
    root 'pages#landing'
  end
  constraints(FrontGroupRouteConstraint.new) do
    root 'front/pages#root'
  end
  root 'home#show'

  get '/g/:group_slug/:parti_slug', to: redirect('https://%{group_slug}.parti.xyz/p/%{parti_slug}')
  get '/robots.:format', to: 'pages#robots'

  resources :users, except: :show do
    collection do
      get 'access_token'
      get 'pre_sign_up'
      put 'notification'
      get 'inactive_sign_up'
      get 'cancel_form'
    end
    member do
      post 'cancel'
    end
  end
  unless Rails.env.production?
    get 'kill_me', to: 'users#kill_me'
  end
  resources :issue_push_notification_preferences
  resources :group_push_notification_preferences

  class MergedIssueRouteConstraint
    def matches?(request)
      group = fetch_group(request) || Group.open_square
      params = request.params
      MergedIssue.exists?(source_slug: params[:slug], source_group_slug: group.slug)
    end
  end


  get '/p/:slug/', to: redirect { |path_params, request|
    group = fetch_group(request) || Group.open_square
    URI.escape("/p/#{Rack::Utils.escape MergedIssue.find_by(source_slug: path_params[:slug], source_group_slug: group.slug).issue.slug}")
  }, constraints: MergedIssueRouteConstraint.new
  get '/p/:slug/', to: redirect { |path_params, request|
    group = fetch_group(request) || Group.open_square
    issue = group.issues.find_by!(slug: path_params[:slug])
    "/front/channels/#{issue.id}"
  }, constraints: FrontGroupRouteConstraint.new
  get '/p/:slug/*path', to: redirect { |path_params, request|
    group = fetch_group(request) || Group.open_square
    merged_issue = MergedIssue.find_by(source_slug: path_params[:slug], source_group_slug: group.slug)
    URI.escape("/p/#{Rack::Utils.escape merged_issue.issue.slug}/#{path_params[:path]}")
  }, constraints: MergedIssueRouteConstraint.new

  get 'search', to: 'search#show', as: 'search'

  # home
  get 'home/group_home_all_posts', to: 'home#group_home_all_posts', as: :group_home_all_posts_home
  get 'home/group_home_discussion_posts', to: 'home#group_home_discussion_posts', as: :group_home_discussion_posts_home

  resources :parties, as: :issues, controller: 'issues' do
    member do
      delete :remove_logo
      delete :remove_cover
      get :destroy_form
      get :new_admit_members
      post :admit_members
      put :add_my_menu
      put :wake
      put :freeze
      delete :remove_my_menu
      put :update_category
      delete :destroy_category
      post :read_all
      get :header
      post :unread_until
    end
    collection do
      get :search_by_tags
      post :merge
      get :selections
    end
    resources :members do
      collection do
        put :organizer
        delete :organizer
        delete :cancel
        delete :ban
        get :ban_form
        post :update_profile
      end
    end
    resources :member_requests do
      post :accept, on: :collection
      delete :reject, on: :collection
      get :reject_form, on: :collection
    end
  end

  concern :upvotable do
    resources :upvotes do
      collection do
        delete :cancel
        get :users
      end
    end
  end

  get 'rails/posts/:id/poll_social_card.png', to: 'posts#poll_social_card', as: :poll_social_card_post
  get 'rails/posts/:id/survey_social_card.png', to: 'posts#survey_social_card', as: :survey_social_card_post

  resources :posts, concerns: :upvotable do
    shallow do
      resources :comments, concerns: :upvotable
    end
    member do
      get 'move_to_issue_form'
      patch 'move_to_issue'
      post 'pin'
      delete 'unpin'
      get 'beholders'
      get 'unbeholders'
      put 'behold'
      put 'unbehold'
      get 'more_comments'
      get 'show_decision'
      patch 'update_decision'
      get 'decision_histories'
      get 'edit_folder'
      patch 'update_folder'
      patch 'update_title'
      get 'wiki'
      patch 'wiki', to: 'posts#update_wiki'
      namespace :wiki, module: nil, controller: "wikis" do
        patch 'purge'
        patch 'activate'
        patch 'inactivate'
        get 'histories'
      end
    end
    collection do
      get 'new_wiki'
      get 'pinned'
    end
  end
  post 'comments/read', to: 'comments#read'
  resources :folders do
    member do
      delete :detach_post
      post :attach_post
    end
    collection do
      get :new_post_form
      get :move_form
      post :move
      post :sort
      get :attach_post_form
    end
  end
  resources 'wiki_histories'
  resources 'decision_histories'

  post 'feedbacks', to: 'feedbacks#create'
  get '/feedbacks/all_users', to: 'feedbacks#all_users', as: :all_users_feedbacks
  get '/feedbacks/users', to: 'feedbacks#users', as: :users_feedbacks
  resources :options do
    member do
      put :cancel
      put :reopen
    end
  end
  resources :bookmarks do
    member do
      post :add_tag
      delete :remove_tag
    end
  end

  resources :polls do
    shallow do
      resources :votings do
        get :users, on: :collection
      end
    end
  end
  get 'links_or_files', to: 'links_or_files#index'
  get 'polls_or_surveys', to: 'polls_or_surveys#index'
  get 'wikis', to: 'wikis#index'

  resources :events do
    get :reload, on: :member
    shallow do
      resources :roll_calls do
        collection do
          patch :attend
          patch :to_be_decided
          patch :absent
          get :invite_form
          post :invite
          patch :accept
          patch :reject
          patch :hold
        end
      end
    end
  end

  resources :relateds
  resources :messages do
    get :mentions, on: :collection
    # NEED_TO_V3
    get :fcm_read, on: :member
  end
  get '/front/messages/:message_id/fcm_read', to: redirect(path: '/messages/%{message_id}/fcm_read')
  resources :invitations

  namespace :group do
    resource :configuration do
      member do
        post 'main_wiki'
        delete 'main_wiki', to: 'configurations#destroy_main_wiki'
        delete :remove_key_visual_foreground_image
        delete :remove_key_visual_background_image
        post :spin_off
      end
    end
    resources :members do
      collection do
        get 'me'
        put :organizer
        delete :organizer
        get :ban_form
        delete :ban
        delete :cancel
        post :admit
        get :new_admit
        get :edit_magic_link
        post :magic_link
        delete :delete_magic_link
        get :magic_form
        post :magic_join
        post :update_profile
        get :join_group_form
        get :invite_issues_form
        post :invite_issues
      end
    end
    resources :member_requests do
      collection do
        post :accept
        delete :reject
        get :reject_form
      end
    end
    resources :managements do
      collection do
        post :suggest
      end
    end
    resources :categories
    namespace :eduhope do
      resources :members do
        collection do
          post :admit
        end
      end
    end
    resources :group_home_components do
      member do
        patch :up_seq
        patch :down_seq
      end
      collection do
        delete '/', to: 'group_home_components#destroy_all'
      end
    end
  end

  get 'file_source/:id/download', to: "file_sources#download", as: :download_file_source

  get 'my_menus', to: "my_menus#index"
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
  get '/p/:slug/references', to: "issues#slug_links_or_files", as: 'slug_issue_links_or_files'
  get '/p/:slug/wikis', to: "issues#slug_wikis", as: 'slug_issue_wikis'
  get '/p/:slug/polls', to: redirect('/p/%{slug}/polls_or_surveys')
  get '/p/:slug/polls_or_surveys', to: "issues#slug_polls_or_surveys", as: 'slug_issue_polls_or_surveys'
  get '/p/:slug/folders', to: "issues#slug_folders", as: 'slug_issue_folders'
  get '/p/:slug/members', to: "issues#slug_members", as: 'slug_issue_users'
  get '/p/:slug/new_posts_count', to: "issues#new_posts_count", as: 'new_issue_posts_count'
  get '/p/:slug/hashtags/:hashtag', to: "issues#slug_hashtag", as: :slug_issue_hashtags
  get '/u/:slug', to: "users#posts", as: 'slug_user'

  get '/privacy', to: "pages#privacy", as: 'privacy'
  get '/privacy/v1', to: "pages#privacy_v1", as: 'privacy_v1'
  get '/terms', to: "pages#terms", as: 'terms'
  get '/terms/v1', to: "pages#terms_v1", as: 'terms_v1'
  if Rails.env.development?
    get '/score', to: "pages#score"
    get '/analyze', to: "pages#analyze"
  end
  get '/share_telegram', to: "pages#share_telegram", as: :share_telegram

  get '/hashtags/:hashtag', to: "hashtags#show", as: :hashtag

  authenticate :user, lambda { |u| u.admin? } do
    get '/test/summary', to: "users#summary_test"
  end

  get '/dev/components', to: 'pages#components'

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/devel/emails"
  end

  namespace :'mobile_app' do
    get 'start', to: 'pages#start'
    get 'sessions/restore', to: 'sessions#restore', as: :restore_sessions
    get 'sessions/setup', to: 'sessions#setup', as: :setup_sessions
    get 'sessions/teardown', to: 'sessions#teardown', as: :teardown_sessions
    get 'auth/:provider', to: 'auth_callbacks#new', as: :auth
    get 'auth/:provider/wait', to: 'auth_callbacks#wait', as: :auth_wait
    get 'auth/:provider/callback', to: 'auth_callbacks#create', as: :auth_callback
  end

  namespace :admin do
    root to: 'monitors#index'
    resources :issues do
      post 'merge', on: :collection
      post 'freeze', on: :collection
      put 'blind', on: :collection
      put 'unblind', on: :member
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
        get 'stat'
      end
    end
    resources :groups do
      post :update_plan, on: :member
      put 'blind', on: :collection
      put 'unblind', on: :member
    end
    resources :blinds
    resources :active_issue_stats
    resources :landing_pages do
      post :save, on: :collection
    end

    get :fetch_posts, to: 'landing_pages#fetch_posts'
    get :new_notice_email, to: 'notice_email#new'
    post :deliver_notice_email, to: 'notice_email#deliver'

    resources :exports, only: [:index] do
      collection do
        post 'group'
        get 'status'
        get 'download'
      end
    end

    resources :reports
  end

  resources :reports

  # front
  get :dock, to: 'pages#dock', as: :dock
  get :landing, to: 'pages#landing', as: :landing
  get :expedition, to: 'pages#expedition', as: :expedition

  namespace :front, defaults: { namespace_slug: 'front' } do
    get :all, to: 'pages#all'
    get :announcements, to: 'pages#announcements'
    get :mentions, to: 'messages#mentions'
    get :messages, to: 'messages#index'
    patch :read_all_posts, to: 'pages#read_all_posts'
    get :search, to: 'pages#search' #, as: :search
    get :group_sidebar, to: 'pages#group_sidebar'
    get :coc, to: 'pages#coc'
    get :menu, to: 'pages#menu'
    get :search_form, to: 'pages#search_form'

    resources :channels, only: [:show, :edit, :new] do
      member do
        get :destroy_form
        patch :read_all_posts
        patch :wake
        post 'main_wiki'
        delete 'main_wiki', to: 'channels#destroy_main_wiki'
      end
      collection do
        get :sync
        get :frozen
      end

      resources :folders, only: [] do
        collection do
          get :form
        end
      end
    end
    resources :issues, only: [:update, :create, :destroy], controller: '/issues' do
      member do
        put :freeze
        put :wake
        delete :remove_logo
        delete :remove_cover
      end
    end

    resources :posts, only: [:show, :new, :edit] do
      member do
        get :destroyed
        get :edit_title
        get :cancel_title_form
        patch :title, action: 'update_title'
        patch :label, action: 'update_label'
        get :edit_channel
        patch :channel, action: 'update_channel'
        patch :announcement, action: 'update_announcement'
      end
      shallow do
        resources :comments, only: [:create, :update, :destroy], controller: '/comments' do
          resources :upvotes, controller: '/upvotes' do
            collection do
              delete :cancel
              get :users
            end
          end
        end
        resources :comments, only: [] do
          shallow do
            resources :comment_histories, only: [:index, :show]
          end
        end
      end
      resources :upvotes, controller: '/upvotes' do
        collection do
          delete :cancel
          get :users
        end
      end
    end
    resources :posts, only: [:create, :update, :destroy], controller: '/posts' do
      member do
        patch 'wiki', to: '/posts#update_wiki'
        post 'pin'
        delete 'unpin'
      end
    end

    resources :polls, only: [] do
      shallow do
        resources :votings, only: [:create], controller: '/votings' do
          get :users, on: :collection
        end
      end
    end

    resources :announcements, only: [] do
      member do
        post :notice
        delete :hold_back
        post :stop
        post :restart
        get :audiences
      end
    end

    resources :options, only: [:create, :destroy], controller: '/options' do
      member do
        put :cancel
        put :reopen
      end
    end

    post 'feedbacks', to: '/feedbacks#create'
    get '/feedbacks/all_users', to: 'feedbacks#all_users'
    get '/feedbacks/users', to: 'feedbacks#users'

    resources :users, except: :show do
      collection do
        # get 'access_token'
        get 'pre_sign_up'
        get 'email_sign_in'
        # put 'notification'
        get 'inactive_sign_up'
        get 'cancel_form'
      end
      # TODO
      #member do
      #   post 'cancel'
      #end
    end

    resources :member_requests, only: [:new, :index, :show, :create] do
      collection do
        get :intro
        get :reject_form
      end
    end
    resources :member_requests, only: [], controller: '/group/member_requests' do
      collection do
        post :accept
        delete :reject
      end
    end
    resources :invitations, only: [:index, :new, :destroy] do
      collection do
        post :bulk
      end
      member do
        get :accept
        patch :resend
      end
    end

    resources :members, only: [], controller: '/group/members' do
      member do
        delete :cancel
      end
      collection do
        put :organizer
        delete :organizer
        delete :ban
      end
    end
    resources :members, only: [:show, :index] do
      collection do
        get :ban_form
        get 'user/:user_id', action: 'user', as: :user
        get :edit_me
        post :update_me
      end
      member do
        get :statement
      end
    end

    resources :messages, only: [] do
      member do
        patch :read
        patch :unread
      end
      collection do
        get :nav
        patch :read_all
        patch :read_all_mentions
        patch :read_cluster
        patch :notice
        get :cluster
      end
    end

    resources :groups, only: [:edit]
    resources :groups, only: [:update], controller: '/group/configurations'
    resources :groups, only: [] do
      collection do
        post 'main_wiki', to: '/group/configurations#main_wiki'
        delete 'main_wiki', to: '/group/configurations#destroy_main_wiki'
        delete 'remove_key_visual_foreground_image', to: '/group/configurations#remove_key_visual_foreground_image'
      end
    end

    resources :categories, only: [] do
      collection do
        get :edit_current_group
        patch :move
      end
      member do
        patch :sort
      end
    end
    resources :categories, only: [:create, :update, :destroy], controller: '/group/categories'

    resources :labels, only: [:index, :create, :update, :destroy]

    resources :bookmarks, only: [:index, :create, :destroy]

    resources :message_configuration_group_observations, only: [:create, :update]
    resources :message_configuration_issue_observations, only: [:create, :update, :destroy]
    resources :message_configuration_post_observations, only: [:create, :update, :destroy]

    resources :reports, only: [:new, :create], controller: '/reports'
  end
end
