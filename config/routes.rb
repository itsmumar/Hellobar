Rails.application.routes.draw do
  root "welcome#index"

  get "/admin", :to => "admin#index", :as => :admin
  namespace :admin do
    get "lockdown/:email/:key/:timestamp", :to => "access#lockdown", :constraints => {:email => /[^\/]+/}, :as => :lockdown
    get "validate_access_token/:email/:key/:timestamp", :to => "access#validate_access_token", :constraints => {:email => /[^\/]+/}, :as => :validate_access_token
  end
end
