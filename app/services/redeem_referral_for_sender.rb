class RedeemReferralForSender
  class ReferralNotAvailable < StandardError
  end

  def initialize(referral)
    @referral = referral
    @site = Site.with_deleted.find_by(id: referral.site_id)
    @subscription = site&.active_subscription
  end

  def call
    raise ReferralNotAvailable unless referral.available_to_sender

    if last_failed_bill
      PayBill.new(last_failed_bill).call
    else
      bill = add_free_days_or_trial
      use_referral bill
    end
  end

  private

  attr_reader :referral, :site, :subscription

  def add_free_days_or_trial(period = 1.month)
    AddFreeDaysOrTrialSubscription.new(site, period).call
  end

  def use_referral(bill)
    UseReferral.new(bill, referral).call
  end

  def last_failed_bill
    return if subscription.blank?
    @last_failed_bill ||= subscription.bills.failed.last
  end
end
