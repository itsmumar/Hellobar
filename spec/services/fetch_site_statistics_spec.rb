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
        create(:site_element_statistics_record, date: '2017-01-01', site_element: site_element),
        create(:site_element_statistics_record, date: '2017-01-02', site_element: site_element),
        create(:site_element_statistics_record, date: '2017-01-03', site_element: site_element)
      ]
    end

    let!(:request) do
      body = { 'Items': records.map(&:json) }
      date = convert_to_weird_date(days_limit.days.ago)
      stub_request(:post, 'https://dynamodb.us-east-1.amazonaws.com/')
        .with(
          body: %r{"TableName":"over_time".+":last_date":{"N":"#{ date }"}.+":sid":{"N":"#{ site_element.id }"}.+"Limit":#{ days_limit }},
          headers: { 'X-Amz-Target' => 'DynamoDB_20120810.Query' }
        ).and_return(body: body.to_json)
    end

    it 'sends scan query to DynamoDB' do
      service.call
      expect(request).to have_been_made
    end

    it 'returns a hash site_element_id => BarStatistics' do
      expect(service.call).to be_a SiteStatistics
      expect(service.call.views).to eql records.sum(&:views).to_f
      expect(service.call.conversions).to eql records.sum(&:conversions).to_f
    end

    context 'when Aws::DynamoDB::Errors::ServiceError is raised' do
      before do
        allow_any_instance_of(Aws::DynamoDB::Client)
          .to receive(:query).and_raise(Aws::DynamoDB::Errors::ServiceError.new(double('context'), 'message'))
        allow(Rails.env).to receive(:test?).and_return false
      end

      it 'sends error to Raven' do
        expect(Raven)
          .to receive(:capture_exception)
          .with(an_instance_of(Aws::DynamoDB::Errors::ServiceError), context: { request: instance_of(Hash) })

        service.call
      end

      it 'returns {}' do
        expect(service.call).to be_a SiteStatistics
        expect(service.call).to be_empty
      end
    end
  end
end
