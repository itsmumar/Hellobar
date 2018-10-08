Rails.application.routes.draw do
  use_doorkeeper do
    skip_controllers :applications, :token_info
  end

  resources :referrals do
    collection do
      get :accept
    end
  end

  namespace :api do
    # Used by Ember.js
    resources :settings, only: :index

    resources :user_state, only: :show

    # Used by Vue.js
    post :authenticate, controller: :authentications

    resources :sites, only: [] do
      resources :campaigns, except: %i[new edit] do
        member do
          post :send_out
          post :send_out_test_email
          post :archive
        end
      end

      resources :contact_lists, only: [] do
        resources :subscribers, param: :email, email: /.+/, except: %i[new edit show]
      end

      resources :sequences, except: %i[new edit] do
        resources :steps, except: %i[new edit], controller: 'sequence_steps'
      end

      resource :whitelabel, only: %i[create show destroy] do
        member do
          post :validate
        end
      end

      resources :emails, only: %i[create show update]
    end

    # Used by Lambda functions
    namespace :internal do
      resources :campaigns, only: [] do
        member do
          post :update_status
        end
      end

      resources :sites, only: [] do
        member do
          post :update_install_type
          post :update_static_script_installation
        end
      end
    end

    namespace :external do
      get '/me', to: 'user#show', as: :me

      resources :sites, only: %i[index] do
        resources :contact_lists, only: %i[index] do
          resources :subscribers, only: %i[index]

          member do
            post :subscribe
            post :unsubscribe
          end
        end
      end
    end
  end

  devise_for :users, controllers: { sessions: 'users/sessions', passwords: 'users/passwords' }

  get '/users/sign_up', to: 'registrations#new'
  post '/users/sign_up', to: 'registrations#create'

  devise_scope :user do
    post '/users/find_email', to: 'users/sessions#find_email', as: :find_email
    get '/users/forgot_email', to: 'users/forgot_emails#new', as: :new_forgot_email
    post '/users/forgot_email', to: 'users/forgot_emails#create', as: :forgot_email
  end

  post '/users/:user_id/update_exit_intent', to: 'user_campaign#update_exit_intent', as: :update_user_exit_intent
  post '/users/:user_id/update_upgrade_suggest', to: 'user_campaign#update_upgrade_suggest', as: :update_user_upgrade_suggest

  get '/auth/:action/callback', controller: 'users/omniauth_callbacks', constraints: { action: /google_oauth2|subscribers/ }
  get '/auth/:action', controller: 'users/omniauth_callbacks', constraints: { action: /google_oauth2/ }, as: :oauth_login

  get 'profile', to: 'user#edit', as: :profile
  resource :user, controller: :user, only: %i[update destroy create]
  get 'user/new/:invite_token', to: 'user#new', as: :invite_user

  resources :sites do
    resource :privacy, only: %i[edit update]

    member do
      put :downgrade
      post :install_check
    end

    get 'team'

    resource :wordpress_plugin, controller: :wordpress_plugin

    put 'site_elements/:id/toggle_paused', to: 'site_elements#toggle_paused', as: :site_element_toggle_paused
    resources :site_elements
    get 'site_elements/:id/edit/*path', to: 'site_elements#edit'
    get 'site_elements/new/*path', to: 'site_elements#new'

    resources :content_upgrades do
      member do
        put :toggle_paused
      end
      collection do
        get :style_editor
        post :update_styles
      end
    end

    resources :autofills, except: :show

    resources :image_uploads, only: [:create]

    resources :rules do
      resources :conditions
    end

    resources :identities
    resources :contact_lists do
      member do
        get :export
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

  resources :credit_cards, only: %i[index new create]
  resource :subscription, only: %i[update]
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

  post '/contact_submissions/email_developer', to: 'contact_submissions#email_developer', as: 'email_developer_contact_submission'
  post '/contact_submissions/generic_message', to: 'contact_submissions#generic_message', as: 'generic_message_contact_submission'
  post '/user/trigger_for_amplitude', to: 'user#trigger_for_amplitude'
  post '/user/checkout_trigger_for_amplitude', to: 'user#checkout_trigger_for_amplitude'

  resources :authorized_applications, only: %i[index destroy]

  get '/admin', to: 'admin/users#index', as: :admin

  namespace :admin do
    post 'users/:id/impersonate', to: 'users#impersonate', as: :impersonate_user
    delete 'users/unimpersonate', to: 'users#unimpersonate', as: :unimpersonate_user

    resources :admins, only: :index do
      member do
        put :unlock
      end
    end

    resources :contact_lists, only: %i[show]

    resources :credit_cards, only: %i[show destroy]

    resources :users, only: %i[index show destroy] do
      member do
        post :reset_password
      end
    end

    resources :sites, only: %i[show update] do
      member do
        post :regenerate
        put :add_free_days
      end

      resources :contact_lists, only: %i[index]
    end

    resources :bills, only: %i[index show] do
      collection do
        get 'filter/:status', action: 'filter_by_status', as: :filter_by_status
      end

      member do
        get 'receipt'
        put 'void'
        put 'pay'
        put 'refund'
        put 'chargeback'
      end
    end

    resources :subscriptions, only: %i[index show] do
      collection do
        get :trial
        get :ended_trial
        get :deleted
        get 'filter/:type', action: 'filter_by_type', as: :filter_by_type
      end
    end

    resources :partners

    get 'lockdown/:email/:key/:timestamp', to: 'access#lockdown', constraints: { email: /[^\/]+/ }, as: :lockdown
    get 'logout', to: 'access#logout_admin', as: :logout
    get 'reset_password', to: 'access#reset_password'
    post 'reset_password', to: 'access#do_reset_password'
    get 'access', to: 'access#step1', as: :access
    post 'access', to: 'access#process_step1'
    get 'otp', to: 'access#step2', as: :otp
    post 'access/authenticate', to: 'access#process_step2', as: :authenticate
    get 'locked', to: 'access#locked', as: :locked
  end

  get '/install' => 'sites#install_redirect'
  get '/logged_out' => 'pages#logout_confirmation', as: :logout_confirmation

  get '/heartbeat' => 'heartbeat#index'
  get '/login', to: redirect('/users/sign_in')
  get '/signup', to: redirect('/users/sign_up')

  get '/proxy/:scheme/*url', to: 'proxy#proxy' if Rails.env.development?

  %w[404 422 500].each do |code|
    get code, to: 'errors#show', code: code
  end

  resources :test_sites, only: :show
  resource :test_site, only: :show, as: :latest_test_site

  root 'pages#index'

  get '*unmatched_route', to: 'errors#show', code: 404
end
