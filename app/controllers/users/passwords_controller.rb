class Users::PasswordsController < Devise::PasswordsController
  skip_before_action :require_no_authentication, only: [:update]

  layout 'static'
end
