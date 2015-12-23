class ReferralsController < ApplicationController
  before_action :authenticate_user!, except: [:accept]

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
    token = ReferralToken.where(token: params[:token]).first
    session[:referral_token] = params[:token] if token.present?
    redirect_to root_path
  end

  private

  def referral_params
    params.require(:referral).permit(:email, :body)
  end
end
