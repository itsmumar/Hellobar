class ReferralsController < ApplicationController
  def index
    @referral = current_site.referrals.build
    render
  end
end
