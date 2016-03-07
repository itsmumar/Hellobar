Rails.application.routes.draw do
  resources :referrals do
    collection do
      get :accept
    end
  end

  devise_for :users, :controllers => {:sessions => "users/sessions", :passwords => "users/passwords"}

  devise_scope :user do
    post "/users/find_email", to: "users/sessions#find_email", as: :find_email

    get "/users/forgot_email", to: "users/forgot_emails#new", as: :new_forgot_email
    post "/users/forgot_email", to: "users/forgot_emails#create", as: :forgot_email
  end

  get "/auth/:action/callback", :to => "users/omniauth_callbacks", :constraints => { :action => /google_oauth2/ }

  get "profile", :to => "user#edit", :as => :profile
  resource :user, :controller => :user, :only => [:update, :destroy, :create]
  get "user/new/:invite_token", :to => "user#new", :as => :invite_user

  resources :sites do
    member do
      put :downgrade
    end

    get "team"

    resource :wordpress_plugin, :controller => :wordpress_plugin

    put "site_elements/:id/toggle_paused", to: "site_elements#toggle_paused", as: :site_element_toggle_paused
    resources :site_elements

    resources :image_uploads, only: [:create]

    resources :rules do
      resources :conditions
    end

    resources :identities
    resources :contact_lists
    resources :targeted_segments

    resources :site_memberships do
      collection do
        post "invite"
      end
    end
  end

  namespace :modals do
    get :registration
  end

  resources :payment_methods, only: [:index, :create, :update]
  resources :bills, only: :show

  get "continue_create_site", :to => "sites#create", :as => :continue_create_site
  get "sites/:id/install", :to => "sites#install", :as => :site_install
  get "sites/:id/improve", :to => "sites#improve", :as => :site_improve
  get "sites/:id/preview_script", :to => "sites#preview_script", :as => :preview_script
  get "sites/:id/script", :to => "sites#script", :as => :script
  get "sites/:id/chart_data", to: "sites#chart_data", as: :chart_data
  get "sites/:id/whats_new", :to => "sites#whats_new", :as => :whats_new

  get "/auth/:provider/callback", :to => "identities#create"

  %w(email_developer generic_message).each do |sub|
    post "/contact_submissions/#{sub}", :to => "contact_submissions##{sub}", :as => "#{sub}_contact_submission"
  end

  get "/admin", :to => "admin/users#index", :as => :admin
  namespace :admin do
    post "users/:id/impersonate", :to => "users#impersonate", :as => :impersonate_user
    delete "users/unimpersonate", :to => "users#unimpersonate", :as => :unimpersonate_user

    resources :admins, only: :index do
      member do
        put :unlock
      end
    end

    resources :payment_method_details, only: [] do
      put 'remove_cc_info'
    end

    resources :users, :only => [:index, :show, :destroy] do
      resources :sites, :only => [:update] do
        member do
          post :regenerate
        end
      end

      resources :bills, :only => [:show] do
        put 'void'
        put 'refund'
      end
    end

    get "lockdown/:email/:key/:timestamp", :to => "access#lockdown", :constraints => {:email => /[^\/]+/}, :as => :lockdown
    get "validate_access_token/:email/:key/:timestamp", :to => "access#validate_access_token", :constraints => {:email => /[^\/]+/}, :as => :validate_access_token
    get "logout", :to => "access#logout_admin", :as => :logout
    get "reset_password", :to => "access#reset_password"
    post "reset_password", :to => "access#do_reset_password"
    get "access", :to => "access#step1", :as => :access
    post "access/authenticate", :to => "access#process_step2", :as => :authenticate
    post "access", :to => "access#process_step1"
    get "locked", :to => "access#locked", :as => :locked
  end

  post "/track/current_person/did/:event" => "tracking#track_current_person"
  post "/track/:type/:id/did/:event" => "tracking#track"
  get "/pixel.gif" => "tracking#pixel", :as => :tracking_pixel

  get '/use-cases' => 'pages#use_cases'
  get '/amazon' => 'pages#use_cases'
  get '/terms-of-use' => 'pages#terms_of_use'
  get '/privacy-policy' => 'pages#privacy_policy'
  get '/logged_out' => 'pages#logout_confirmation', as: :logout_confirmation


  get "/heartbeat" => "heartbeat#index"
  get "/login", to: redirect("/users/sign_in")
  get "/signup", to: redirect("/")

  get "/user_migration", to: "user_migration#new", as: :new_user_migration
  get "/upgrade", to: "user_migration#upgrade", as: :user_migration_landing
  post "/start_migration", to: "user_migration#start", as: :start_user_migration
  post "/user_migration", to: "user_migration#create", as: :user_migration

  %w( 404 422 500 ).each do |code|
    get code, :to => "errors#show", :code => code
  end

  get "/proxy/:scheme/*url", to: "proxy#proxy" if Rails.env.development?

  get "/email-signup", to: "welcome#email_quickstart"
  root "welcome#index"
end
