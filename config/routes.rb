Rails.application.routes.draw do
  devise_for :users, :controllers => {:sessions => "users/sessions", :passwords => "users/passwords"}
  root "welcome#index"

  get "profile", :to => "user#edit", :as => :profile
  resource :user, :controller => :user, :only => [:update]

  resources :sites do
    resource :wordpress_plugin, :controller => :wordpress_plugin

    put "site_elements/:id/toggle_paused", to: "site_elements#toggle_paused", as: :site_element_toggle_paused
    resources :site_elements
    resources :rules
    resources :identities

    get "contact_lists/inflight", :to => "contact_lists#inflight", :as => :inflight_contact_list
    resources :contact_lists
  end

  namespace :modals do
    get :registration
  end

  get "sites/:id/preview_script", :to => "sites#preview_script", :as => :preview_script

  get "/auth/:provider/callback", :to => "identities#create"

  %w(email_developer generic_message).each do |sub|
    post "/contact_submissions/#{sub}", :to => "contact_submissions##{sub}", :as => "#{sub}_contact_submission"
  end

  get "/admin", :to => "admin#index", :as => :admin
  namespace :admin do
    resources :users, :only => [:index]
    post "users/:id/impersonate", :to => "users#impersonate", :as => :impersonate_user
    delete "users/unimpersonate", :to => "users#unimpersonate", :as => :unimpersonate_user

    get "lockdown/:email/:key/:timestamp", :to => "access#lockdown", :constraints => {:email => /[^\/]+/}, :as => :lockdown
    get "validate_access_token/:email/:key/:timestamp", :to => "access#validate_access_token", :constraints => {:email => /[^\/]+/}, :as => :validate_access_token
    get "logout", :to => "access#logout_admin", :as => :logout
    get "reset_password", :to => "access#reset_password"
    post "reset_password", :to => "access#do_reset_password"
    get "access", :to => "access#step1"
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
end
