class RedeemReferralForSender
  class ReferralNotAvailable < StandardError
  end

  def initialize(referral)
    @referral = referral
    @site = referral.site
    @subscription = site.active_subscription
  end

  def call
    raise ReferralNotAvailable unless referral.available_to_sender

    if last_failed_bill
      PayBill.new(last_failed_bill).call
    else
      update_subscription
    end
  end

  private

  attr_reader :referral, :site, :subscription

  def update_subscription
    bill = add_free_days_or_trial
    use_referral bill
  end

  def add_free_days_or_trial(period = 1.month)
    if subscription&.paid?
      AddFreeDays.new(referral.site, period).call
    else
      AddTrialSubscription.new(site, subscription: 'pro', trial_period: period).call
    end
  end

  def use_referral(bill)
    UseReferral.new(bill, referral).call
  end

  def last_failed_bill
    return if subscription.blank?
    @last_failed_bill ||= subscription.bills.failed.last
  end
end
