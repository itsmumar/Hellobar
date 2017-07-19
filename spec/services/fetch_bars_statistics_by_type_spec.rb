describe FetchBarStatisticsByType do
  let!(:site) { create :site, :with_rule }
  let!(:site_element_traffic) { create :site_element, :traffic, site: site }
  let!(:site_element_email) { create :site_element, :email, site: site }
  let!(:site_element_call) { create :site_element, :call, site: site }
  let!(:site_element_twitter) { create :site_element, :twitter, site: site }
  let!(:site_element_facebook) { create :site_element, :facebook, site: site }
  let(:service) { FetchBarStatisticsByType.new(site, days_limit: 5) }

  describe '#call', freeze: '2017-01-05' do
    let!(:request) do
      body = {
        'Items': [
          { 'v' => { 'N': 100 }, 'c' => { 'N': 10 }, 'date' => { 'N': 17001 }, 'sid' => { 'N': site_element_traffic.id } },
          { 'v' => { 'N': 100 }, 'c' => { 'N': 10 }, 'date' => { 'N': 17002 }, 'sid' => { 'N': site_element_email.id } },
          { 'v' => { 'N': 100 }, 'c' => { 'N': 10 }, 'date' => { 'N': 17003 }, 'sid' => { 'N': site_element_call.id } },
          { 'v' => { 'N': 100 }, 'c' => { 'N': 10 }, 'date' => { 'N': 17001 }, 'sid' => { 'N': site_element_twitter.id } },
          { 'v' => { 'N': 100 }, 'c' => { 'N': 10 }, 'date' => { 'N': 17002 }, 'sid' => { 'N': site_element_facebook.id } }
        ]
      }

      stub_request(:post, 'https://dynamodb.us-east-1.amazonaws.com/')
        .with(
          body: /"TableName":"over_time"/,
          headers: { 'X-Amz-Target' => 'DynamoDB_20120810.Scan' }
        ).and_return(body: body.to_json)
    end

    it 'sends scan query to DynamoDB' do
      service.call
      expect(request).to have_been_made
    end

    it 'returns BarStatistics::Totals' do
      expect(service.call).to an_instance_of(BarStatistics::Totals)
      expect(service.call.total).to eql BarStatistics::Total.new(500, 50)
      expect(service.call.email).to eql BarStatistics::Total.new(100, 10)
      expect(service.call.call).to eql BarStatistics::Total.new(100, 10)
      expect(service.call.social).to eql BarStatistics::Total.new(200, 20)
      expect(service.call.traffic).to eql BarStatistics::Total.new(100, 10)
    end
  end
end
