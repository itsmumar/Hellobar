# Freeze on a Tuesday
describe CalculateInternalMetrics, freeze: '2017-12-05 15:00 UTC' do
  let(:metrics) { CalculateInternalMetrics.new.call }

  describe '#call' do
    it 'is about 1 week period from Sunday to Sunday' do
      expect(metrics.beginning_of_last_week).to eq Date.parse('2017-11-26')
      expect(metrics.beginning_of_current_week).to eq Date.parse('2017-12-03')
    end

    it 'does not mess with the default `Date.beginning_of_week`' do
      metrics

      expect(Date.beginning_of_week).to eql :monday
    end

    it 'includes users registered in the 1 week period' do
      user = create :user, created_at: 1.week.ago
      create :user, created_at: 2.weeks.ago

      expect(metrics.users).to match_array [user]
    end

    it 'includes sites created in the 1 week period' do
      site = create :site, created_at: 1.week.ago
      create :site, created_at: 2.weeks.ago

      expect(metrics.sites).to match_array [site]
    end

    it 'includes installed sites' do
      site = create :site, created_at: 1.week.ago,
        script_installed_at: 6.days.ago,
        script_uninstalled_at: 5.days.ago

      expect(metrics.installed_sites).to match_array [site]
    end

    it 'includes still installed sites' do
      site = create :site, :installed, created_at: 1.week.ago
      uninstalled_site = create :site, created_at: 1.week.ago,
        script_uninstalled_at: 5.days.ago

      expect(metrics.sites).to match_array [site, uninstalled_site]
      expect(metrics.still_installed_sites).to match_array [site]
    end

    it 'includes installation churn' do
      create :site, created_at: 1.week.ago, script_installed_at: 4.days.ago
      create :site, created_at: 1.week.ago, script_installed_at: 4.days.ago,
        script_uninstalled_at: 3.days.ago

      expect(metrics.installation_churn).to eql 0.5
    end

    it 'includes Pro revenue from the 1 week period' do
      site = create :site, :installed, :pro, created_at: 1.week.ago
      bill = create :bill, :pro, :paid, subscription: site.current_subscription,
        created_at: 1.week.ago, bill_at: 1.week.ago

      expect(metrics.revenue).to match_array [bill]
      expect(metrics.pro).to match_array [bill]
      expect(metrics.pro_monthly).to match_array [bill]
      expect(metrics.pro_yearly).to match_array []
      expect(metrics.elite_monthly).to match_array []
      expect(metrics.elite_yearly).to match_array []
      expect(metrics.revenue_sum).to eq bill.amount
    end

    it 'includes Elite revenue from the 1 week period' do
      site = create :site, :installed, :elite, created_at: 1.week.ago
      bill = create :bill, :elite, :paid, subscription: site.current_subscription,
        created_at: 1.week.ago, bill_at: 1.week.ago

      expect(metrics.revenue).to match_array [bill]
      expect(metrics.pro).to match_array []
      expect(metrics.pro_monthly).to match_array []
      expect(metrics.elite_monthly).to match_array [bill]
      expect(metrics.elite_yearly).to match_array []
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
