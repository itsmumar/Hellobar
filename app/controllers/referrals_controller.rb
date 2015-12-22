class ReferralsController < ApplicationController
  def index
    @referral = current_user.referrals.build
    @referral.set_standard_body
  end

  def create
    @referral = current_user.referrals.build(referral_params)
    @referral.state = "sent"
    if @referral.save
      flash[:success] = "We've sent an invite to your friend. Check back here to see whether they've accepted it and redeem any free months."
    else
      puts @referral.errors.inspect
      flash[:error] = "Sorry, but there was a problem while sending this invite."
    end
    redirect_to referrals_path
  end

  private

  def referral_params
    params.require(:referral).permit(:email, :body)
  end
end
