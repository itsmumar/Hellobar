class Admin::PaymentMethodDetailsController < ApplicationController
  before_action :require_admin

  def remove_cc_info
    cc = CyberSourceCreditCard.find params[:payment_method_detail_id]
    cc.delete_token if cc && cc.token_present?

    redirect_to admin_users_path
  end
end

