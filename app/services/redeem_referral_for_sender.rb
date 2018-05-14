class RedeemReferralForSender
  class ReferralNotAvailable < StandardError
  end

  def initialize(referral)
    @referral = referral
    @site = Site.with_deleted.find_by(id: referral.site_id)
    @subscription = site&.active_subscription
  end

  def call
    return unless site
    raise ReferralNotAvailable unless referral.available_to_sender

    if last_failed_bill
      mark_failed_bill_as_paid
    else
      add_free_days_or_trial_and_use_referral
    end

    track_event
  end

  private

  attr_reader :referral, :site, :subscription

  def add_free_days_or_trial_and_use_referral
    Referral.transaction do
      bill = add_free_days_or_trial
      use_referral bill
    end
  end

  def add_free_days_or_trial(period = 1.month)
    subscription = Subscription.pro_or_growth_for(referral.sender).name
    AddFreeDaysOrTrialSubscription.new(site, period, subscription: subscription).call
  end

  def use_referral(bill)
    UseReferral.new(bill, referral).call
  end

  def mark_failed_bill_as_paid
    if subscription.monthly?
      last_failed_bill.pay!
      CreateBillForNextPeriod.new(last_failed_bill).call
    else
      Raven.capture_exception(
        'Trying to redeem referral for sender that has a failed bill',
        extra: {
          referral: referral.inspect,
          site: site.inspect,
          last_failed_bill: last_failed_bill.inspect
        }
      )
    end
  end

  def last_failed_bill
    return if subscription.blank?
    @last_failed_bill ||= subscription.bills.failed.last
  end

  def track_event
    TrackEvent.new(
      :used_sender_referral_coupon,
      user: referral.sender,
      subscription: site.current_subscription
    ).call
  end
end
