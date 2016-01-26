require 'spec_helper'

describe Referrals::RedeemForRecipient do
  fixtures :users
  before :each do
    create(:referral_coupon)
    ownership = create(:site_ownership)
    @site = ownership.site
    @user = ownership.user

    @site.change_subscription(build(:free_subscription))
  end

  it "subscribes to Pro with a 0.00 bill when referred and signed_up" do
    referral = create(:referral, recipient: @user, state: :signed_up)
    Referrals::RedeemForRecipient.run(site: @site)
    bill = @site.current_subscription.active_bills.last

    referral.reload

    expect(referral.installed?).to be_true
    expect(referral.redeemed_by_recipient_at).not_to be_nil
    expect(referral.available_to_sender).to be_true
    expect(@site.current_subscription).to be_a(Subscription::Pro)
    expect(bill.amount).to eq(0.0)
    expect(bill.discount).to eq(Coupon::REFERRAL_AMOUNT)
  end

  it "subscribes to Pro with a 0.00 bill but only once" do
    referral = create(:referral, recipient: @user, state: :signed_up)
    Referrals::RedeemForRecipient.run(site: @site)

    @site.stub(:change_subscription)
    Referrals::RedeemForRecipient.run(site: @site)
    expect(@site).not_to have_received(:change_subscription)
  end

  it "sends out an email to the referral sender when referred" do
    referral = create(:referral, recipient: @user, state: :signed_up)

    expect(MailerGateway).to receive(:send_email) do |name, email, params|
      expect(name).to eq('Referral Successful')
      expect(email).to eq(referral.sender.email)
      expect(params[:referral_sender]).to eq(referral.sender.first_name)
      expect(params[:referral_recipient]).to eq(referral.recipient.name)
    end

    Referrals::RedeemForRecipient.run(site: @site)
  end

  it "raises an exception which is captured in Sentry when referred and merely sent" do
    create(:referral, recipient: @user, state: :sent)
    expect(Raven).to receive(:capture_exception)

    Referrals::RedeemForRecipient.run(site: @site)
  end

  it "raises nothing when no referral exists" do
    expect(lambda do
      Referrals::RedeemForRecipient.run(site: @site)
    end).not_to raise_error
    expect(@site.current_subscription).to be_a(Subscription::Free)
  end
end