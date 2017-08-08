class Users::PasswordsController < Devise::PasswordsController
  skip_before_action :require_no_authentication, if: proc { |ctrl| current_admin.present? || ctrl.action_name == 'update' }

  layout 'static'
end
