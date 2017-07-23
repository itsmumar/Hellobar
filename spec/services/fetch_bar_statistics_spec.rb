describe FetchBarStatistics do
  let!(:site) { create :site, :with_rule }
  let!(:site_element) { create :site_element, site: site }
  let(:service) { FetchBarStatistics.new(site, days_limit: 5) }

  describe '#call', freeze: '2017-01-05' do
    let(:records) do
      [
        create(:bar_statistics, date: '2017-01-01', site_element: site_element),
        create(:bar_statistics, date: '2017-01-02', site_element: site_element),
        create(:bar_statistics, date: '2017-01-03', site_element: site_element)
      ]
    end

    let!(:request) do
      body = { 'Items': records.map(&:json) }

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

    it 'returns a hash site_element_id => BarStatistics' do
      expect(service.call).to match site_element.id => an_instance_of(BarStatistics)
      expect(service.call[site_element.id].views).to eql records.sum(&:views)
      expect(service.call[site_element.id].conversions).to eql records.sum(&:conversions)
    end

    context 'when Aws::DynamoDB::Errors::ServiceError is raised' do
      before do
        allow_any_instance_of(Aws::DynamoDB::Client)
          .to receive(:scan).and_raise(Aws::DynamoDB::Errors::ServiceError.new(double('context'), 'message'))
        allow(Rails.env).to receive(:test?).and_return false
      end

      it 'sends error to Raven' do
        expect(Raven)
          .to receive(:capture_exception)
          .with(an_instance_of(Aws::DynamoDB::Errors::ServiceError), context: { request: instance_of(Hash) })

        service.call
      end

      it 'returns {}' do
        expect(service.call).to eql({})
      end
    end
  end
end
