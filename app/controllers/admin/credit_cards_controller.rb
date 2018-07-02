class Admin::CreditCardsController < AdminController
  def show
    @credit_card = CreditCard.with_deleted.find params[:id]
    @bills = Bill.where(id: @credit_card.billing_attempts.pluck(:bill_id))
  end

  def destroy
    credit_card = CreditCard.find params[:id]
    credit_card.update!(token: nil)
    credit_card.destroy

    redirect_to admin_users_path
  end
end
