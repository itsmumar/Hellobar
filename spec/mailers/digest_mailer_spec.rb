describe DigestMailer do
  describe 'weekly_digest' do
    let(:site) { create(:site, :with_user, elements: [:email]) }
    let(:user) { site.owners.first }
    let(:mail) { DigestMailer.weekly_digest(site, user) }
    let(:views) { Array.new(6) { 1 } }
    let(:conversions) { Array.new(6) { 1 } }
    let(:statistics) do
      SiteStatistics.new(site.site_elements.map { |element|
        [element.id, create(:site_element_statistics, views: views, conversions: conversions)]
      }.to_h)
    end

    it 'should work correctly when there are no site elements' do
      site.site_elements.each(&:destroy)
      site.reload
      expect(FetchSiteStatistics).to receive_service_call.and_return(SiteStatistics.new)
      expect { mail.body }.not_to raise_error
    end

    it 'should display n/a if history is too short' do
      # Travel to one day past the delivery date to ensure it's picking up the
      # mocked data regardless of when the test runs
      travel_to(EmailDigestHelper.date_of_previous('Sunday') + 1.day) do
        expect(FetchSiteStatistics)
          .to receive_service_call.with(site, days_limit: 90).and_return(statistics).exactly(2).times
        expect(FetchSiteStatistics)
          .to receive_service_call.with(site, days_limit: 7).and_return(statistics)
        expect(mail.body.encoded).to match('n/a')
      end
    end

    it 'should be nil if there were no views in the past week' do
      expect(FetchSiteStatistics)
        .to receive_service_call.with(site, days_limit: 90).and_return({})
      expect { mail.deliver_now }.not_to raise_error
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end
end
