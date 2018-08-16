describe FetchTotalViewsForMonth do
  let(:site) { create :site, :with_rule }
  let(:site_element) { create :site_element, site: site }
  let(:service) { FetchTotalViewsForMonth.new([site]) }
  let(:search_url) { "#{ Settings.elastic_search_endpoint }/test_over_time/over_time_type/_search" }
  let(:from_date) { WeirdDate.from_date(Date.current.beginning_of_month) }
  let(:to_date) { WeirdDate.from_date(Date.current.end_of_month) }
  let(:number_of_views) { 42 }

  let(:request) do
    {
      aggs: {
        site.id.to_s => {
          filter: { terms: { sid: [site_element.id] } },
          aggs: { total_views: { sum: { field: 'v' } } }
        }
      },
      query: {
        bool: { filter: { range: { date: { gte: from_date, lte: to_date } } } }
      }
    }
  end

  let(:response) do
    {
      took: 6,
      timed_out: false,
      _shards: {
        total: 5,
        successful: 5,
        skipped: 0,
        failed: 0
      },
      hits: {
        total: 129415,
        max_score: 0,
        hits: []
      },
      aggregations: {
        site.id.to_s => {
          doc_count: 4,
          total_views: {
            value: number_of_views
          }
        }
      }
    }
  end

  before do
    stub_request(:get, search_url)
      .with(body: request)
      .to_return(
        status: 200,
        body: response.to_json,
        headers: { 'content-type' => 'application/json; charset=UTF-8' }
      )
  end

  it 'queries elastic search via OverTimeIndex' do
    expect(service.call).to eql site.id => number_of_views
  end
end
