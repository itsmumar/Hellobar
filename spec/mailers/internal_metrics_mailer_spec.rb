describe InternalMetricsMailer, freeze: '2017-12-10 23:00 UTC' do
  describe '.summary' do
    let(:mail) { InternalMetricsMailer.summary }

    it 'renders the email' do
      site = create :site, :pro, :installed, created_at: 1.week.ago

      # uninstalled site
      create :site, created_at: 1.week.ago

      create :bill, :pro, :paid, subscription: site.current_subscription,
        created_at: 1.week.ago, bill_at: 1.week.ago

      expect(mail.subject).to include '2 new sites'
      expect(mail.subject).to include '50.0% install'
      expect(mail.subject).to include '$15.00'
      expect(mail.to).to eq ['dev@hellobar.com']
      expect(mail.from).to eq ['contact@hellobar.com']
      expect(mail.body.encoded).to include 'Pro (Monthly): 1'
      expect(mail.body.encoded).to include '($15.00)'
    end
  end
end
