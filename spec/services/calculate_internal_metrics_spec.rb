describe CalculateInternalMetrics, freeze: '2017-12-10 23:00 UTC' do
  let(:metrics) { CalculateInternalMetrics.new.call }

  describe '#call' do
    it 'is about 1 week period' do
      expect(metrics.last_week).to eq Date.parse('2017-12-05')
      expect(metrics.two_weeks_ago).to eq Date.parse('2017-11-28')
    end

    it 'includes sites created in the 1 week period' do
      site = create :site, created_at: 1.week.ago
      create :site, created_at: 2.weeks.ago

      expect(metrics.sites).to match_array [site]
    end

    it 'includes installed sites' do
      site = create :site, :installed, created_at: 1.week.ago
      uninstalled_site = create :site, created_at: 1.week.ago

      expect(metrics.sites).to match_array [site, uninstalled_site]
      expect(metrics.installed_sites).to match_array [site]
    end

    it 'includes Pro revenue from the 1 week period' do
      site = create :site, :installed, :pro, created_at: 1.week.ago
      bill = create :bill, :pro, :paid, subscription: site.current_subscription,
        created_at: 1.week.ago, bill_at: 1.week.ago

      expect(metrics.revenue).to match_array [bill]
      expect(metrics.pro).to match_array [bill]
      expect(metrics.pro_monthly).to match_array [bill]
      expect(metrics.pro_yearly).to match_array []
      expect(metrics.enterprise_monthly).to match_array []
      expect(metrics.enterprise_yearly).to match_array []
      expect(metrics.revenue_sum).to eq bill.amount
    end

    it 'includes Enterprise revenue from the 1 week period' do
      site = create :site, :installed, :enterprise, created_at: 1.week.ago
      bill = create :bill, :enterprise, :paid, subscription: site.current_subscription,
        created_at: 1.week.ago, bill_at: 1.week.ago

      expect(metrics.revenue).to match_array [bill]
      expect(metrics.pro).to match_array []
      expect(metrics.pro_monthly).to match_array []
      expect(metrics.enterprise_monthly).to match_array [bill]
      expect(metrics.enterprise_yearly).to match_array []
      expect(metrics.revenue_sum).to eq bill.amount
    end

    it 'includes revenue from refunded bills (perhaps it should not)' do
      site = create :site, :installed, :pro, created_at: 1.week.ago
      bill = create :bill, :pro, :paid, subscription: site.current_subscription,
        created_at: 1.week.ago, bill_at: 1.week.ago

      create :refund_bill, :refunded, amount: -bill.amount,
        subscription: site.current_subscription, created_at: 1.week.ago,
        bill_at: 1.week.ago

      expect(metrics.revenue).to match_array [bill]
      expect(metrics.pro).to match_array [bill]
      expect(metrics.revenue_sum).to eq bill.amount
    end

    it 'includes revenue from downgraded subscriptions (perhaps it should not)' do
      site = create :site, :installed, :pro, created_at: 1.week.ago
      bill = create :bill, :pro, :paid, subscription: site.current_subscription,
        created_at: 1.week.ago, bill_at: 1.week.ago

      DowngradeSiteToFree.new(site).call

      expect(metrics.revenue).to match_array [bill]
      expect(metrics.pro).to match_array [bill]
      expect(metrics.revenue_sum).to eq bill.amount
    end
  end
end
