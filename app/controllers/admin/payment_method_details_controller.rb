class Admin::PaymentMethodDetailsController < ApplicationController
  before_action :require_admin

  def remove_cc_info
    card = CyberSourceCreditCard.find(params[:payment_method_detail_id])
    user = User.find(params[:user_id])
    payment_method = user.payment_methods.find(params[:payment_method_detail_id])

    card.delete_token if card.token_present?
    payment_method.destroy

    redirect_to admin_users_path
  end
end
