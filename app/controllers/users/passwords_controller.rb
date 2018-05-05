class Users::PasswordsController < Devise::PasswordsController
  skip_before_action :require_no_authentication, only: [:update] # rubocop:disable Rails/LexicallyScopedActionFilter

  layout 'static'
end
