describe Subscription::Capabilities do
  let(:user) { create(:user) }
  let(:site) { create(:site) }
  let(:payment_method) { create(:payment_method, user: user) }
  let(:free) { create :subscription, :free, user: user, site: site }
  let(:pro) { create :subscription, :pro, user: user, site: site }
  let(:enterprise) { create :subscription, :enterprise, user: user, site: site }
  let(:capabilities) { site.capabilities(true) }
  let(:last_bill) { Bill.last }

  before { stub_cyber_source :purchase, :refund }

  def change_subscription(plan, payment_method, schedule = 'monthly')
    ChangeSubscription.new(site, { plan: plan, schedule: schedule }, payment_method).call
  end

  it 'returns the latest subscription capabilities' do
    site = Site.new
    site.subscriptions << Subscription::Pro.create
    expect(site).to be_capable_of :pro

    site.subscriptions << Subscription::Enterprise.create
    expect(site).to be_capable_of :enterprise
  end

  it 'returns default capabilities for plan' do
    expect(site).to be_capable_of :free
    expect(capabilities).not_to be_closable

    change_subscription('pro', payment_method)

    expect(site).to be_capable_of :pro
  end

  context 'when on a paid plan and payment has not been made' do
    before { expect { change_subscription('pro', payment_method) }.to make_gateway_call(:purchase).and_fail }

    it 'returns ProblemWithPayment capabilities' do
      expect(site).to be_capable_of :problem_with_payment
    end
  end

  context 'when a payment issue has been resolved' do
    before { expect { change_subscription('pro', payment_method) }.to make_gateway_call(:purchase).and_fail }

    it 'returns the previous capabilities' do
      expect(site.capabilities(true).remove_branding?).to be_falsey
      expect(site.capabilities(true).closable?).to be_falsey
      expect(site.site_elements.all?(&:show_branding)).to be_truthy
      expect(site.site_elements.all?(&:closable)).to be_truthy
    end
  end

  context 'when successfully changed subscription' do
    before { expect { change_subscription('pro', payment_method) }.to make_gateway_call(:purchase).and_succeed }

    it 'returns new capabilities' do
      expect(site.capabilities(true).remove_branding?).to be_truthy
      expect(site.capabilities(true).closable?).to be_truthy
      expect(site.site_elements.none?(&:show_branding)).to be_truthy
      expect(site.site_elements.none?(&:closable)).to be_truthy
    end
  end

  context 'when payment is not due yet' do
    it 'returns new capabilities' do
      expect { change_subscription('pro', payment_method) }.to make_gateway_call(:purchase).and_fail

      expect(site).to be_capable_of :problem_with_payment
      # Make the bill not due until later
      last_bill.bill_at += 10.days
      last_bill.save!
      expect(site).to be_capable_of :pro
    end
  end

  context 'when downgrade from enterprise to pro' do
    before { change_subscription('enterprise', payment_method) }
    before { change_subscription('pro', payment_method) }

    it 'returns enterprise capabilities' do
      expect(site).to be_capable_of :enterprise
    end
  end

  it 'should handle refund, switch, and void' do
    pro_bill = change_subscription('pro', payment_method)

    expect(site).to be_capable_of :pro

    # Refund
    refund_bill, refund_attempt = RefundBill.new(pro_bill).call
    expect(site).to be_capable_of :pro

    # Should have a pending bill for pro
    pending = site.bills.pending
    expect(pending.size).to eq(1)
    expect(pending.first.subscription).to be_a Subscription::Pro

    # Switch to Free
    change_subscription('free', payment_method)

    # Should not have pro capabilities
    expect(site).to be_capable_of :free

    # Should have a pending bill for free subscription
    pending = site.bills.pending
    expect(pending.size).to eq(1)
    expect(pending.first.subscription).to be_a Subscription::Free

    # Void the paid bill
    pro_bill.voided!

    # Should not have pro capabilities
    expect(site).to be_capable_of :free

    # Should still have a pending bill for free
    pending = site.bills.pending
    expect(pending.size).to eq(1)
    expect(pending.first.subscription).to be_a Subscription::Free
  end

  it 'gives the greatest capability of all current paid subscriptions' do
    # Auto pays each of these
    change_subscription('enterprise', payment_method)
    change_subscription('pro', payment_method)
    change_subscription('free', payment_method)
    expect(site).to be_capable_of :enterprise
  end

  it 'stays at pro capabilities until bill period is over' do
    pending 'it was actually always broken...'

    bill = change_subscription('pro', payment_method, 'yearly')
    expect(site).to be_capable_of :pro
    travel_to 2.years.from_now do
      expect(site).to be_capable_of :free
    end
  end

  context 'Subscription::ProManaged capabilities' do
    specify 'Subscription::Free does not have the ProManaged capabilities' do
      subscription = build_stubbed :subscription, :free
      capabilities = subscription.capabilities

      expect(capabilities.custom_html?).to be_falsey
      expect(capabilities.content_upgrades?).to be_falsey
      expect(capabilities.autofills?).to be_falsey
      expect(capabilities.geolocation_injection?).to be_falsey
      expect(capabilities.external_tracking?).to be_falsey
      expect(capabilities.alert_bars?).to be_falsey
    end

    specify 'ProManaged plan has certain custom capabilities' do
      subscription = build_stubbed :subscription, :pro_managed
      capabilities = subscription.capabilities

      expect(capabilities.custom_html?).to be_truthy
      expect(capabilities.content_upgrades?).to be_truthy
      expect(capabilities.autofills?).to be_truthy
      expect(capabilities.geolocation_injection?).to be_truthy
      expect(capabilities.external_tracking?).to be_truthy
      expect(capabilities.alert_bars?).to be_truthy
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
