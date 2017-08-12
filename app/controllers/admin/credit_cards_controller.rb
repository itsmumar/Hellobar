class Admin::CreditCardsController < AdminController
  def destroy
    credit_card = CreditCard.find params[:id]
    credit_card.destroy

    redirect_to admin_users_path
  end
end
