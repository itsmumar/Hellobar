describe BillingViewsReport, :freeze do
  let(:sites_count) { 999 }
  let(:report) { BillingViewsReport.new(sites_count) }
  let(:site) { create :site }
  let(:old_site) { create :site }

  before { allow(report).to receive(:puts) }

  before { allow(Settings).to receive(:slack_channels).and_return 'billing' => 'key' }

  matcher :log do |logs|
    supports_block_expectations

    match do |block|
      @level ||= :info

      logs.each do |l|
        allow(BillingLogger).to receive(:info).with(l)
        expect(PostToSlack).to receive_service_call.with(:billing, text: l)
        allow(report).to receive(:puts).with(l)
      end
      block.call
      expect(report.log).to match_array logs
    end
  end

  describe '#start' do
    specify do
      expect { report.start }.to log [
        'test: ' + Time.current.to_s,
        '-' * 80,
        'Found *999* active sites...'
      ]
    end
  end

  describe '#finish' do
    specify do
      expect { report.finish }.to log [
        '-' * 80,
        '*0* sites have been processed',
        '*0* total views',
        '*0* overage views total',
        '*0* overage views on paid plans',
        'test: ' + Time.current.to_s,
        '',
        ''
      ]
    end
  end

  describe '#interrupt' do
    specify do
      expect { report.interrupt(nil) }.to log [
        '---- INTERRUPT ----',
        '-' * 80,
        '*0* sites have been processed',
        '*0* total views',
        '*0* overage views total',
        '*0* overage views on paid plans',
        'test: ' + Time.current.to_s,
        '',
        ''
      ]
    end
  end

  describe '#count' do
    specify do
      expect { 4000.times { report.count(10) } }.to log [
        '2000 sites processed...',
        '4000 sites processed...'
      ]
    end
  end

  describe '#log_grandfathered_site' do
    specify do
      expect { report.log_grandfathered_site(old_site) }.to log [
        "#{ old_site.url } is grandfathered (#{ old_site.active_subscription&.name }) until #{ old_site.active_subscription&.active_until }"
      ]
    end
  end
end
