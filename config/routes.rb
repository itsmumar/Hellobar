Rails.application.routes.draw do
  resources :referrals do
    collection do
      get :accept
    end
  end

  namespace :api do
    resources :user_state, only: :show
    resources :settings, only: :index

    resources :sites, only: [] do
      member do
        post :update_install_type
        post :update_static_script_installation
      end
    end

    resources :email_campaigns, only: [] do
      member do
        post :update_status
      end
    end
  end

  devise_for :users, controllers: { sessions: 'users/sessions', passwords: 'users/passwords' }

  devise_scope :user do
    post '/users/find_email', to: 'users/sessions#find_email', as: :find_email
    get '/users/forgot_email', to: 'users/forgot_emails#new', as: :new_forgot_email
    post '/users/forgot_email', to: 'users/forgot_emails#create', as: :forgot_email
  end

  post '/users/:user_id/update_exit_intent', to: 'user_campaign#update_exit_intent', as: :update_user_exit_intent
  post '/users/:user_id/update_upgrade_suggest', to: 'user_campaign#update_upgrade_suggest', as: :update_user_upgrade_suggest

  get '/auth/:action/callback', controller: 'users/omniauth_callbacks', constraints: { action: /google_oauth2/ }
  get '/auth/:action', controller: 'users/omniauth_callbacks', constraints: { action: /google_oauth2/ }, as: :oauth_login

  get 'profile', to: 'user#edit', as: :profile
  resource :user, controller: :user, only: %i[update destroy create]
  get 'user/new/:invite_token', to: 'user#new', as: :invite_user

  resources :sites do
    member do
      put :downgrade
      post :install_check
    end

    get 'team'

    post :track_selected_goal, to: 'tracking#track_selected_goal'

    resource :wordpress_plugin, controller: :wordpress_plugin

    put 'site_elements/:id/toggle_paused', to: 'site_elements#toggle_paused', as: :site_element_toggle_paused
    resources :site_elements
    get 'site_elements/:id/edit/*path', to: 'site_elements#edit'
    get 'site_elements/new/*path', to: 'site_elements#new'

    resources :content_upgrades, except: :destroy do
      collection do
        get :style_editor
        post :update_styles
      end
    end

    resources :autofills, except: :show

    resources :email_campaigns, except: :destroy

    resources :image_uploads, only: [:create]

    resources :rules do
      resources :conditions
    end

    resources :identities
    resources :contact_lists do
      member do
        get :download
      end
    end

    resources :site_memberships do
      collection do
        post 'invite'
      end
    end
  end

  namespace :modals do
    get :registration
  end

  resources :credit_cards, only: %i[index]
  resource :subscription, only: %i[create update]
  resources :bills, only: :show do
    put :pay, on: :member
  end

  get 'continue_create_site', to: 'sites#create', as: :continue_create_site
  get 'sites/:id/install', to: 'sites#install', as: :site_install
  get 'sites/:id/improve', to: 'sites#improve', as: :site_improve
  get 'sites/:id/preview_script', to: 'sites#preview_script', as: :preview_script
  get 'sites/:id/script', to: 'sites#script', as: :script
  get 'sites/:id/chart_data', to: 'sites#chart_data', as: :chart_data

  get '/auth/:provider/callback', to: 'identities#store'

  resources :contact_submissions, only: [:create]
  get '/contact', to: 'contact_submissions#new', as: :new_contact_submission

  %w[email_developer generic_message].each do |sub|
    post "/contact_submissions/#{ sub }", to: "contact_submissions##{ sub }", as: "#{ sub }_contact_submission"
  end

  get '/admin', to: 'admin/users#index', as: :admin

  namespace :admin do
    post 'users/:id/impersonate', to: 'users#impersonate', as: :impersonate_user
    delete 'users/unimpersonate', to: 'users#unimpersonate', as: :unimpersonate_user

    resources :admins, only: :index do
      member do
        put :unlock
      end
    end

    resources :credit_cards, only: [:destroy]

    resources :users, only: %i[index show destroy] do
      resources :sites, only: [:update] do
        member do
          post :regenerate
          put :add_free_days
        end

        resources :contact_lists, only: [:index]
      end

      resources :bills, only: [:show] do
        put 'void'
        put 'pay'
        put 'refund'
      end
    end

    get 'lockdown/:email/:key/:timestamp', to: 'access#lockdown', constraints: { email: /[^\/]+/ }, as: :lockdown
    get 'logout', to: 'access#logout_admin', as: :logout
    get 'reset_password', to: 'access#reset_password'
    post 'reset_password', to: 'access#do_reset_password'
    get 'access', to: 'access#step1', as: :access
    post 'access/authenticate', to: 'access#process_step2', as: :authenticate
    post 'access', to: 'access#process_step1'
    get 'locked', to: 'access#locked', as: :locked
  end

  post '/track/current_person/did/:event' => 'tracking#track_current_person'
  post '/track/:type/:id/did/:event' => 'tracking#track'
  get '/pixel.gif' => 'tracking#pixel', :as => :tracking_pixel

  get '/install' => 'sites#install_redirect'

  get '/use-cases' => 'pages#use_cases'
  get '/amazon' => 'pages#use_cases'
  get '/terms-of-use' => 'pages#terms_of_use'
  get '/privacy-policy' => 'pages#privacy_policy'
  get '/logged_out' => 'pages#logout_confirmation', as: :logout_confirmation

  get '/heartbeat' => 'heartbeat#index'
  get '/login', to: redirect('/users/sign_in')
  get '/signup', to: redirect('/')

  get '/proxy/:scheme/*url', to: 'proxy#proxy' if Rails.env.development?

  %w[404 422 500].each do |code|
    get code, to: 'errors#show', code: code
  end

  get 'get-started', to: redirect('/')

  root 'welcome#index'

  resources :test_sites, only: :show
  resource :test_site, only: :show, as: :latest_test_site

  get '*unmatched_route', to: 'errors#show', code: 404
end
