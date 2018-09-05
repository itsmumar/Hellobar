describe ResetEmailSentFields do
  subject!(:service) { ResetEmailSentFields.new(site) }

  let(:user) { create :user }
  let(:site) { create :site, user: user, warning_email_one_sent: true, warning_email_two_sent: true, warning_email_three_sent: true, limit_email_sent: true, upsell_email_sent: true }

  context 'when warning emails have been sent' do
    it 'resets warning_email_one_sent to false' do
      service.call
      expect(site.warning_email_one_sent).to eql(false)
      expect(site.warning_email_two_sent).to eql(false)
      expect(site.warning_email_three_sent).to eql(false)
      expect(site.limit_email_sent).to eql(false)
      expect(site.upsell_email_sent).to eql(false)
    end
  end
end
