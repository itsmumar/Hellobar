describe DowngradeSiteToFree, :freeze do
  let(:site) { create :site, :with_rule }
  let!(:site_element) { create :site_element, show_branding: false, site: site }
  let(:credit_card) { create :credit_card }
  let(:service) { DowngradeSiteToFree.new(site) }

  before do
    stub_cyber_source :purchase
    ChangeSubscription.new(site, { subscription: 'pro' }, credit_card).call
    Timecop.travel site.active_subscription.active_until + 1.day
  end

  it 'voids pending bills' do
    expect { service.call }
      .to change { site.bills.pending.count }
      .to(0)
  end

  it 'does not void paid bills' do
    expect { service.call }
      .not_to change { site.bills.paid.count }
  end

  it 'creates Free subscription' do
    expect { service.call }
      .to change { site.current_subscription.class }
      .from(Subscription::Pro)
      .to(Subscription::Free)
  end

  it 'enables branding on all bars' do
    expect { service.call }
      .to change { site_element.reload.show_branding }
      .from(false)
      .to(true)
  end

  it 'does not regenerate script' do
    expect { service.call }
      .not_to have_enqueued_job(GenerateStaticScriptJob)
  end

  context 'when already on Free' do
    before { service.call }

    it 'does not create Free subscription' do
      expect { service.call }
        .not_to change { site.current_subscription }
    end
  end
end
