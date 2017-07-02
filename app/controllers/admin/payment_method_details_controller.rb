class Admin::PaymentMethodDetailsController < AdminController
  def destroy
    card = CyberSourceCreditCard.find params[:id]
    payment_method = card.payment_method

    card.delete_token
    payment_method.destroy

    redirect_to admin_users_path
  end
end
