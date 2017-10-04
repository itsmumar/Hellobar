describe FetchSiteStatistics do
  let!(:site) { create :site, :with_rule }
  let!(:site_element) { create :site_element, site: site }
  let!(:days_limit) { 5 }
  let(:service) { FetchSiteStatistics.new(site, days_limit: days_limit) }

  # see FetchSiteStatistics#convert_to_weird_date
  def convert_to_weird_date(date)
    (date.year - 2000) * 1000 + date.yday
  end

  describe '#call', freeze: '2017-01-05' do
    let(:records) do
      [
        create(:site_statistics_record, date: 3.days.ago, site_element_id: site_element.id),
        create(:site_statistics_record, date: 2.days.ago, site_element_id: site_element.id),
        create(:site_statistics_record, date: 1.day.ago, site_element_id: site_element.id)
      ]
    end

    let(:request_body) do
      date = convert_to_weird_date(days_limit.days.ago)
      %r{"TableName":"edge_over_time2".+":last_date":{"N":"#{ date }"}.+":sid":{"N":"#{ site_element.id }"}.+"Limit":#{ days_limit }}
    end

    def response_body
      items =
        records.map do |record|
          {
            'v' => { 'N': record.views },
            'c' => { 'N': record.conversions },
            'date' => { 'N': convert_to_weird_date(record.date) },
            'sid' => { 'N': record.site_element_id }
          }
        end

      { 'Items': items, 'ConsumedCapacity': {} }.to_json
    end

    let!(:request) do
      stub_request(:post, 'https://dynamodb.us-east-1.amazonaws.com/')
        .with(
          body: request_body,
          headers: { 'X-Amz-Target' => 'DynamoDB_20120810.Query' }
        ).and_return(body: response_body)
    end

    it 'sends query request to DynamoDB' do
      service.call
      expect(request).to have_been_made
    end

    it 'returns SiteStatistics' do
      expect(service.call).to be_a SiteStatistics
      expect(service.call.views).to eql records.sum(&:views)
      expect(service.call.conversions).to eql records.sum(&:conversions)
    end
  end
end
