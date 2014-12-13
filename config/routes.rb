Rails.application.routes.draw do
  devise_for :users, :controllers => {:sessions => "users/sessions", :passwords => "users/passwords"}

  get "profile", :to => "user#edit", :as => :profile
  resource :user, :controller => :user, :only => [:update, :destroy]

  resources :sites do
    resource :wordpress_plugin, :controller => :wordpress_plugin

    put "site_elements/:id/toggle_paused", to: "site_elements#toggle_paused", as: :site_element_toggle_paused
    resources :site_elements
    resources :rules
    resources :identities
    resources :contact_lists
    resources :targeted_segments
  end

  namespace :modals do
    get :registration
  end

  resources :payment_methods, only: [:index, :create, :update]
  resources :bills, only: :show

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
  get "/admin/reports", :to => "admin#reports", :as => :admin_reports
  namespace :admin do
    post "users/:id/impersonate", :to => "users#impersonate", :as => :impersonate_user
    delete "users/unimpersonate", :to => "users#unimpersonate", :as => :unimpersonate_user

    resources :users, :only => [:index, :show, :destroy] do
      resources :bills, :only => [] do
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

  post "/user/:user_id/did/:event" => Hello::Tracking.create_events_endpoint()
  post "/visitor/:visitor_id/did/:event" => Hello::Tracking.create_events_endpoint()
  post "/user/:user_id/has/:prop_name/of/:prop_value" => Hello::Tracking.create_props_endpoint()
  post "/visitor/:visitor_id/has/:prop_name/of/:prop_value" => Hello::Tracking.create_props_endpoint()

  get '/use-cases' => 'pages#use_cases'
  get '/terms-of-use' => 'pages#terms_of_use'
  get '/privacy-policy' => 'pages#privacy_policy'
  get '/logged_out' => 'pages#logout_confirmation', as: :logout_confirmation

  get "/pixel.gif" => "pixel#show", :as => :tracking_pixel

  get "/heartbeat" => "heartbeat#index"
  get "/login", to: redirect("/users/sign_in")
  get "/signup", to: redirect("/")

  root "welcome#index"
end
