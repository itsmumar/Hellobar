describe Referrals::RedeemForRecipient do
  let(:ownership) { create(:site_membership) }
  let(:site) { ownership.site }
  let(:user) { ownership.user }
  let!(:coupon) { create :coupon, :referral }

  before :each do
    ChangeSubscription.new(site, subscription: 'free').call
  end

  it 'subscribes to Pro with a 0.00 bill when referred and signed_up' do
    referral = create(:referral, recipient: user, state: :signed_up)
    Referrals::RedeemForRecipient.run(site: site)
    bill = site.current_subscription.active_bills.last

    referral.reload

    expect(referral.installed?).to be_truthy
    expect(referral.redeemed_by_recipient_at).not_to be_nil
    expect(referral.available_to_sender).to be_truthy
    expect(site.current_subscription).to be_a(Subscription::Pro)
    expect(bill.amount).to eq(0.0)
    expect(bill.discount).to eq coupon.amount
  end

  it 'subscribes the sender to Pro too' do
    sender_ownership = create(:site_membership)
    sender_site = sender_ownership.site
    ChangeSubscription.new(sender_site, subscription: 'free').call

    create(:referral, recipient: user, state: :signed_up, site: sender_site)
    Referrals::RedeemForRecipient.run(site: site)

    expect(sender_site.reload.current_subscription).to be_a(Subscription::Pro)
  end

  it 'subscribes to Pro with a 0.00 bill but only once' do
    create(:referral, recipient: user, state: :signed_up)
    Referrals::RedeemForRecipient.run(site: site)

    expect(ChangeSubscription).not_to receive_service_call
    Referrals::RedeemForRecipient.run(site: site)
  end

  it 'sends out an email to the referral sender when referred' do
    referral = create(:referral, recipient: user, state: :signed_up)

    expect(ReferralsMailer)
      .to receive(:successful)
      .with(referral, user)
      .and_return double(deliver_later: true)

    Referrals::RedeemForRecipient.run(site: site)
  end

  it 'raises an exception which is captured in Sentry when referred and merely sent' do
    create(:referral, recipient: user, state: :sent)
    expect(Raven).to receive(:capture_exception)

    Referrals::RedeemForRecipient.run(site: site)
  end

  it 'raises nothing when no referral exists' do
    expect(lambda do
      Referrals::RedeemForRecipient.run(site: site)
    end).not_to raise_error
    expect(site.current_subscription).to be_a(Subscription::Free)
  end
end
