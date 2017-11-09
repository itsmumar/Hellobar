describe Subscription::Capabilities do
  let(:user) { create(:user) }
  let(:site) { create(:site) }
  let(:credit_card) { create(:credit_card, user: user) }
  let(:free) { create :subscription, :free, user: user, site: site }
  let(:pro) { create :subscription, :pro, user: user, site: site }
  let(:enterprise) { create :subscription, :enterprise, user: user, site: site }
  let(:capabilities) { site.capabilities }
  let(:last_bill) { Bill.last }

  before { stub_cyber_source :purchase, :refund }

  def change_subscription(subscription, credit_card, schedule = 'monthly')
    ChangeSubscription.new(
      site,
      { subscription: subscription, schedule: schedule },
      credit_card
    ).call
  end

  it 'returns the latest subscription capabilities' do
    change_subscription 'pro', credit_card
    expect(site).to be_capable_of :pro

    change_subscription 'enterprise', credit_card
    expect(site).to be_capable_of :enterprise
  end

  it 'returns default capabilities for plan' do
    expect(site).to be_capable_of :free
    expect(capabilities).not_to be_closable

    change_subscription('pro', credit_card)

    expect(site).to be_capable_of :pro
  end

  context 'when successfully changed subscription' do
    before { expect { change_subscription('pro', credit_card) }.to make_gateway_call(:purchase).and_succeed }

    it 'returns new capabilities' do
      expect(site.capabilities.remove_branding?).to be_truthy
      expect(site.capabilities.closable?).to be_truthy
      expect(site.site_elements.none?(&:show_branding)).to be_truthy
      expect(site.site_elements.none?(&:closable)).to be_truthy
    end
  end

  context 'when downgrade from enterprise to pro' do
    before { change_subscription('enterprise', credit_card) }
    before { change_subscription('pro', credit_card) }

    it 'returns enterprise capabilities' do
      expect(site).to be_capable_of :enterprise
    end
  end

  it 'should handle refund, switch, and void' do
    pro_bill = change_subscription('pro', credit_card)

    expect(site).to be_capable_of :pro

    # Refund
    RefundBill.new(pro_bill).call
    expect(site).to be_capable_of :free

    # Void the paid bill
    pro_bill.voided!

    # Should not have pro capabilities
    expect(site).to be_capable_of :free

    # Shouldn't have recurring bills for free
    expect(site.bills.pending).to be_empty
  end

  it 'gives the greatest capability of all current paid subscriptions' do
    # Auto pays each of these
    change_subscription('enterprise', credit_card)
    change_subscription('pro', credit_card)
    change_subscription('free', credit_card)
    expect(site).to be_capable_of :enterprise
  end

  it 'stays at pro capabilities until bill period is over' do
    change_subscription('pro', credit_card, 'yearly')
    expect(site).to be_capable_of :pro
    Timecop.travel 2.years.from_now do
      expect(site).to be_capable_of :free
    end
  end

  context 'Subscription::ProManaged capabilities' do
    specify 'Subscription::Free does not have the ProManaged capabilities' do
      subscription = build_stubbed :subscription, :free
      capabilities = subscription.capabilities

      expect(capabilities.content_upgrades?).to be_falsey
      expect(capabilities.autofills?).to be_falsey
      expect(capabilities.geolocation_injection?).to be_falsey
      expect(capabilities.external_tracking?).to be_falsey
      expect(capabilities.alert_bars?).to be_falsey
      expect(capabilities.advanced_themes?).to be_falsey
      expect(capabilities.email_campaigns?).to be_falsey
    end

    specify 'ProManaged plan has certain custom capabilities' do
      subscription = build_stubbed :subscription, :pro_managed
      capabilities = subscription.capabilities

      expect(capabilities.content_upgrades?).to be_truthy
      expect(capabilities.autofills?).to be_truthy
      expect(capabilities.geolocation_injection?).to be_truthy
      expect(capabilities.external_tracking?).to be_truthy
      expect(capabilities.alert_bars?).to be_truthy
      expect(capabilities.advanced_themes?).to be_truthy
      expect(capabilities.email_campaigns?).to be_truthy
    end
  end

  context '#at_site_element_limit?' do
    it 'returns true when it has as many site elements as it can have' do
      expect(site.capabilities.at_site_element_limit?).to be_falsey
    end

    it 'returns false when it can still add site elements' do
      max_elements = site.capabilities.max_site_elements
      elements = ['element'] * max_elements
      allow(site).to receive(:site_elements).and_return(elements)

      expect(site.capabilities.at_site_element_limit?).to be_truthy
    end
  end
end
