describe AmplitudeSerializer do
  let!(:user) { create :user }
  let!(:first_site) { create :site, user: user }
  let!(:second_site) { create :site, user: user }
  let(:serializer) { AmplitudeSerializer.new(user) }

  let(:conversions) { [1, 2, 3, 4, 5] }
  let(:views) { [1, 2, 3, 4, 5] }

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

  it 'serializes user properties' do
    expect(serializer.as_json).to match(
      user_id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      primary_domain: first_site.normalized_url,
      additional_domains: [first_site, second_site].map(&:normalized_url).join(', '),
      contact_lists: 1,
      total_views: views.sum * user.sites.count,
      total_conversions: conversions.sum * user.sites.count
    )
  end
end
