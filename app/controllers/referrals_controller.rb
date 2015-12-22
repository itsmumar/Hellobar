class ReferralsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:accept]

  def index
    @referral = current_user.sent_referrals.build
    @referral.set_standard_body
  end

  def create
    @referral = current_user.sent_referrals.build(referral_params)
    @referral.state = "sent"
    if @referral.save
      flash[:success] = "We've sent an invite to your friend. Check back here to see whether they've accepted it and redeem any free months."
    else
      flash[:error] = "Sorry, but there was a problem while sending this invite."
    end
    redirect_to referrals_path
  end

  def accept
    sender = User.where(referral_token: params[:token]).first
    if sender.present? && current_user.blank?
      session[:referral_sender_id] = sender.id
    end
    redirect_to root_path
  end

  private

  def referral_params
    params.require(:referral).permit(:email, :body)
  end
end
