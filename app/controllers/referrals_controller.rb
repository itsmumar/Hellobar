class ReferralsController < ApplicationController
  def index
    @referral = current_user.referrals.build
    render
  end
end
