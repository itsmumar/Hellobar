Rails.application.routes.draw do
  devise_for :users
  root "welcome#index"

  resources :sites

  get "/admin", :to => "admin#index", :as => :admin
  namespace :admin do
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
end
