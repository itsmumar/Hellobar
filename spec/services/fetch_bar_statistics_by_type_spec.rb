describe FetchBarStatisticsByType do
  let!(:site) { create :site, :with_rule }
  let!(:site_element_traffic) { create :site_element, :traffic, site: site }
  let!(:site_element_email) { create :site_element, :email, site: site }
  let!(:site_element_call) { create :site_element, :call, site: site }
  let!(:site_element_twitter) { create :site_element, :twitter, site: site }
  let!(:site_element_facebook) { create :site_element, :facebook, site: site }
  let!(:days_limit) { 5 }
  let(:service) { FetchBarStatisticsByType.new(site, days_limit: days_limit) }

  # see FetchBarStatistics#convert_to_weird_date
  def convert_to_weird_date(date)
    (date.year - 2000) * 1000 + date.yday
  end

  describe '#call', freeze: '2017-01-05' do
    let(:traffic) { create(:bar_statistics_record, date: '2017-01-01', site_element: site_element_traffic) }
    let(:email) { create(:bar_statistics_record, date: '2017-01-02', site_element: site_element_email) }
    let(:call) { create(:bar_statistics_record, date: '2017-01-03', site_element: site_element_call) }
    let(:twitter) { create(:bar_statistics_record, date: '2017-01-01', site_element: site_element_twitter) }
    let(:facebook) { create(:bar_statistics_record, date: '2017-01-02', site_element: site_element_facebook) }
    let!(:all) { [email, call, traffic, facebook, twitter] }
    let(:total_views) { (traffic.views + email.views + call.views + twitter.views + facebook.views).to_f }
    let(:total_conversions) do
      (traffic.conversions + email.conversions + call.conversions + twitter.conversions + facebook.conversions).to_f
    end

    let!(:requests) do
      date = convert_to_weird_date(days_limit.days.ago)

      all.map do |record|
        stub_request(:post, 'https://dynamodb.us-east-1.amazonaws.com/')
          .with(
            body: %r{"TableName":"over_time".+":last_date":{"N":"#{ date }"}.+":sid":{"N":"#{ record.site_element.id }"}.+"Limit":#{ days_limit }},
            headers: { 'X-Amz-Target' => 'DynamoDB_20120810.Query' }
          ).and_return(body: { 'Items' => [record.json] }.to_json)
      end
    end

    it 'sends scan query to DynamoDB' do
      service.call
      requests.each { |request| expect(request).to have_been_made }
    end

    it 'returns BarStatistics::Totals' do
      expect(service.call).to an_instance_of(BarStatistics::Totals)
      expect(service.call.total).to eql BarStatistics::Total.new(total_views, total_conversions)
      expect(service.call.traffic).to eql BarStatistics::Total.new(traffic.views.to_f, traffic.conversions.to_f)
      expect(service.call.email).to eql BarStatistics::Total.new(email.views.to_f, email.conversions.to_f)
      expect(service.call.call).to eql BarStatistics::Total.new(call.views.to_f, call.conversions.to_f)
      expect(service.call.social)
        .to eql BarStatistics::Total.new((twitter.views + facebook.views).to_f, (twitter.conversions + facebook.conversions).to_f)
    end
  end
end
