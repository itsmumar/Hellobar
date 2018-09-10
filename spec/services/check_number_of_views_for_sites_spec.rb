describe CheckNumberOfViewsForSites do
  let!(:site) { create :site }
  let(:sites) { Site.all }
  let(:service) { CheckNumberOfViewsForSites.new(sites) }
  let(:report) { BillingViewsReport.new(1) }
  let(:number_of_views) { 1000 }

  before do
    allow(BillingViewsReport).to receive(:new).and_return report
    allow(report).to receive(:start)
    allow(report).to receive(:finish)
    allow(report).to receive(:count)
    allow(report).to receive(:limit_exceeded)
    allow(report).to receive(:send_warning_email)
    allow(report).to receive(:send_upsell_email)
    allow(report).to receive(:send_enterprise_upsell_email)
    allow(report).to receive(:log_grandfathered_site)
    allow(FetchTotalViewsForMonth)
      .to receive_service_call.and_return(Hash[site.id => number_of_views])

    allow(HandleOverageSite).to receive_service_call
  end

  it 'calls report' do
    service.call
    expect(report).to have_received(:start)
    expect(report).to have_received(:count).exactly(1).times.with(number_of_views)
    expect(report).to have_received(:finish)
  end

  context 'when limit exceeded' do
    let(:number_of_views) { site.views_limit + 1 }

    it 'calls report.limit_exceeded' do
      service.call
      expect(report)
        .to have_received(:limit_exceeded)
        .with(site, number_of_views, site.views_limit)
    end

    it 'calls HandleOverageSite' do
      perform_enqueued_jobs do
        expect(HandleOverageSite).to receive_service_call
        service.call
      end
    end
  end

  context 'when limit exceeded for grandfathered enterprise subscription' do
    let(:number_of_views) { 500_001 }
    let(:credit_card) { create :credit_card }

    before do
      stub_cyber_source :purchase
      Timecop.travel '2018-08-15 13:00 UTC' do
        ChangeSubscription.new(site, { subscription: 'enterprise', schedule: 'yearly' }, credit_card).call
      end
    end

    it 'enterprise subscription is grandfathered and does not call report.limit_exceeded' do
      service.call
      expect(report)
        .to_not have_received(:limit_exceeded)
      expect(report)
        .to have_received(:log_grandfathered_site)
    end

    it 'renews for another year for enterprise and now gets limits enforced' do
      Timecop.travel '2019-08-17 13:00 UTC' do
        PayBill.new(site.bills.last).call
      end

      service.call
      expect(report)
        .to have_received(:limit_exceeded)
      expect(report)
        .to_not have_received(:log_grandfathered_site)
    end

    it 'growth subscription is grandfathered and does not call report.limit_exceeded' do
      service.call
      expect(report)
        .to_not have_received(:limit_exceeded)
      expect(report)
        .to have_received(:log_grandfathered_site)
      # expect(BillingLogger).to receive(:info).with("Site is grandfathered")
    end

    it 'renews for another year for enterprise and now gets limits enforced' do
      Timecop.travel '2019-08-17 13:00 UTC' do
        PayBill.new(site.bills.last).call
      end

      service.call
      expect(report)
        .to have_received(:limit_exceeded)
      expect(report)
        .to_not have_received(:log_grandfathered_site)
    end
  end

  context 'when limit exceeded for grandfathered growth subscription' do
    let(:number_of_views) { 50_001 }
    let(:credit_card) { create :credit_card }

    before do
      stub_cyber_source :purchase
      Timecop.travel '2018-08-15 13:00 UTC' do
        ChangeSubscription.new(site, { subscription: 'growth', schedule: 'yearly' }, credit_card).call
      end
    end

    it 'growth subscription is grandfathered and does not call report.limit_exceeded' do
      service.call
      expect(report)
        .to_not have_received(:limit_exceeded)
      expect(report)
        .to have_received(:log_grandfathered_site)
    end

    it 'renews for another year for growth and now gets limits enforced' do
      Timecop.travel '2019-08-17 13:00 UTC' do
        PayBill.new(site.bills.last).call
      end

      service.call
      expect(report)
        .to have_received(:limit_exceeded)
      expect(report)
        .to_not have_received(:log_grandfathered_site)
    end
  end

  context 'when first limit is approaching for all subscriptions' do
    let(:number_of_views) { site.visit_warning_one + 1 }
    let(:limit) { site.views_limit }
    let(:warning_level_one) { site.visit_warning_one }

    it 'sends warning email for warning number one' do
      service.call
      expect(report)
        .to have_received(:send_warning_email)
    end

    it 'does not call HandleOverageSite' do
      perform_enqueued_jobs do
        expect(HandleOverageSite).not_to receive_service_call
        service.call
      end
    end
  end

  context 'when second limit warning is approaching' do
    let(:number_of_views) { site.visit_warning_two + 1 }
    let(:limit) { site.views_limit }
    let(:warning_level_two) { site.visit_warning_two }

    it 'sends warning email for warning number two for free sites' do
      service.call
      expect(report)
        .to have_received(:send_warning_email)
    end
  end

  context 'when third limit warning is approaching' do
    let(:number_of_views) { site.visit_warning_three + 1 }
    let(:limit) { site.views_limit }
    let(:warning_level_two) { site.visit_warning_three }

    it 'sends warning email for warning number three for free sites' do
      service.call
      expect(report)
        .to have_received(:send_warning_email)
    end
  end

  context 'when it would be cheaper for a user to upgrade' do
    let(:number_of_views) { site.upsell_email_trigger + 1 }
    let(:limit) { site.views_limit }
    let(:upsell_trigger) { site.upsell_email_trigger }

    it 'sends an upsell email' do
      service.call
      expect(report)
        .to have_received(:send_upsell_email)
    end
  end

  context 'when and an elite user needs a custom plan' do
    let(:number_of_views) { site.upsell_email_trigger + 1 }
    let(:limit) { site.views_limit }
    let(:upsell_trigger) { site.upsell_email_trigger }
    let(:credit_card) { create :credit_card }
    before do
      stub_cyber_source :purchase
      ChangeSubscription.new(site, { subscription: 'elite' }, credit_card).call
    end

    it 'sends an notification email to get a custom plan' do
      service.call
      expect(report)
        .to have_received(:send_elite_upsell_email)
    end
  end

  context 'when exception is raised' do
    let(:error) { StandardError.new('OOPS!') }

    before { expect(report).to receive(:start).and_raise(error) }

    it 'stops processing' do
      expect(report).to receive(:interrupt).with(error)
      expect(Raven).to receive(:capture_exception).with(error)
      expect { service.call }.to raise_error error
    end
  end
end
