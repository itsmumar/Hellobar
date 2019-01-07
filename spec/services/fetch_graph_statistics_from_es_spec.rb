describe FetchGraphStatisticsFromES do
  let(:site) { create :site, :with_rule }
  let(:site_element) { create :site_element, site: site }
  let(:search_url) { "#{ Settings.elastic_search_endpoint }/test_over_time/test_over_time_type/_search" }
  let(:from_date) { '2018-01-01'.to_date }
  let(:to_date) { '2018-01-30'.to_date }
  let(:service) { FetchGraphStatisticsFromES.new(site, from_date, to_date, 'total') }
  let(:min_date) { 18001 }
  let(:max_date) { 18030 }

  let(:request) do
    {
      aggs:
      {
        by_date: { terms: { field: 'date', size: 30 }, aggs: { total_views: { sum: { field: 'v' } } } }
      },
      query:
      {
        bool: { filter: [{ range: { date: { gte: 18001, lte: 18030 } } }, { terms: { sid: [] } }] }
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
        by_date:
          {
            doc_count_error_upper_bound: 0,
            sum_other_doc_count: 0,
            buckets: [
              { key: min_date, doc_count: 2, total_views: { value: 6 } },
              { key: 18002, doc_count: 2, total_views: { value: 2 } },
              { key: 18003, doc_count: 1, total_views: { value: 7 } },
              { key: max_date, doc_count: 1, total_views: { value: 45 } }
            ]
          }
      }
    }
  end

  before do
    stub_request(:get, search_url)
      .with(body: request.to_json)
      .to_return(
        status: 200,
        body: response.to_json,
        headers: { 'content-type' => 'application/json; charset=UTF-8' }
      )

    allow_any_instance_of(FetchGraphStatisticsFromES).to((receive :call)).and_call_original
  end

  it 'queries elastic search and last element in the array should be sorted to be the max date' do
    expect(service.call.last[:date]).to eql WeirdDate.to_date(max_date).strftime('%-m/%d')
  end

  it 'queries elastic search and first element in the array should be sorted to be the min date' do
    expect(service.call.first[:date]).to eql WeirdDate.to_date(min_date).strftime('%-m/%d')
  end

  it 'queries elastic search and should return data for missing dates also' do
    expect(service.call.count).to eql((to_date - from_date + 1).to_i)
  end
end
