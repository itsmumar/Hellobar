describe DigestMailer do
  describe 'weekly_digest' do
    let(:site) { create(:site, :with_user, elements: [:email]) }
    let(:site_element) { site.site_elements.first }
    let(:user) { site.owners.first }
    let(:mail) { DigestMailer.weekly_digest(site, user) }
    let(:views) { Array.new(6) { 1 } }
    let(:conversions) { Array.new(6) { 1 } }

    let(:statistics) do
      create :site_statistics,
        site_element_id: site_element.id,
        views: views,
        conversions: conversions
    end

    context 'when there are no site elements' do
      let(:statistics) { create :site_statistics }

      it 'does not raise error' do
        site.site_elements.each(&:destroy)
        site.reload
        expect(FetchSiteStatistics).to receive_service_call.and_return(statistics)
        expect { mail.body }.not_to raise_error
      end
    end

    context 'when history is too short' do
      it 'displays n/a' do
        # Travel to one day past the delivery date to ensure it's picking up the
        # mocked data regardless of when the test runs
        travel_to(EmailDigestHelper.date_of_previous('Sunday') + 1.day) do
          expect(FetchSiteStatistics)
            .to receive_service_call.with(site, days_limit: 7).and_return(statistics)
          expect(FetchSiteStatistics)
            .to receive_service_call.with(site, days_limit: 90).and_return(statistics)
          expect(mail.body.encoded).to match('n/a')
        end
      end
    end

    it 'should be nil if there were no views in the past week' do
      expect(FetchSiteStatistics)
        .to receive_service_call.with(site, days_limit: 90).and_return(SiteStatistics.new)
      expect { mail.deliver_now }.not_to raise_error
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end
end
