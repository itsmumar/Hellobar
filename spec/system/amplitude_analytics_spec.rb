describe AmplitudeAnalytics do
  describe '#fire_event' do
    let!(:user) { create :user }
    let(:first_site) { create :site, user: user }
    let(:second_site) { create :site, user: user }
    let(:site_element) { create :site_element, site: first_site }
    let!(:sites) { [first_site, second_site] }

    let(:views) { [2, 3, 4, 5, 6] }
    let(:conversions) { [1, 2, 3, 4, 5] }
    let(:total_views) { views.sum * 2 }
    let(:total_conversions) { conversions.sum * 2 }

    before do
      create :contact_list, site: first_site

      expect(FetchSiteStatistics)
        .to receive_service_call
        .with(first_site, days_limit: 7)
        .and_return(create(:site_statistics, views: views, conversions: conversions))

      expect(FetchSiteStatistics)
        .to receive_service_call
        .with(second_site, days_limit: 7)
        .and_return(create(:site_statistics, views: views, conversions: conversions))
    end

    it 'sends an event to Amplitude' do
      event_type = 'installed-script'
      event_properties = {
        site: first_site,
        user: user
      }

      request_body_regexp = %r{
        event_type.+#{ event_type }.+
        user_id.+#{ user.id }.+
        user_properties.+
        additional_domains.+
        #{ NormalizeURI[first_site.url].domain }.+
        #{ NormalizeURI[second_site.url].domain }.+
        total_views.+#{ total_views }.+
        total_conversions.+#{ total_conversions }.+
        sites_count.+#{ sites.size }.+
        site_elements_count.+#{ user.site_elements.size }.+
      }x

      stub_request(:post, 'https://api.amplitude.com/httpapi')
        .with(body: request_body_regexp)
        .to_return(status: 200)

      AmplitudeAnalytics.new.fire_event event_type, event_properties
    end
  end
end
