describe FetchSiteStatisticsFromES do
  let(:site) { create :site, :with_rule }
  let(:site_element) { create :site_element, site: site }
  let(:search_url) { "#{ Settings.elastic_search_endpoint }/test_over_time/test_over_time_type/_search" }
  let(:from_date) { Date.new(2015) }
  let(:to_date) { Date.current.end_of_month }
  let(:service) { FetchSiteStatisticsFromES.new(site, from_date, to_date) }
  let(:total) { 50 }

  let(:request) do
    {
      aggs: {
        total: { filter: { terms: { sid: [] } }, aggs: { v: { sum: { field: 'v' } } } },
        call: { filter: { terms: { sid: [] } }, aggs: { c: { sum: { field: 'c' } } } },
        email: { filter: { terms: { sid: [] } }, aggs: { c: { sum: { field: 'c' } } } },
        traffic: { filter: { terms: { sid: [] } }, aggs: { c: { sum: { field: 'c' } } } },
        social: { filter: { terms: { sid: [] } }, aggs: { c: { sum: { field: 'c' } } } }
      },
      query: {
        bool: {
          filter: [
            {
              range: {
                date: {
                  gte: WeirdDate.from_date(from_date),
                  lte: WeirdDate.from_date(to_date)
                }
              }
            },
            { terms: { sid: [] } }
          ]
        }
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
        total: 10,
        max_score: 0,
        hits: []
      },
      aggregations: {
        call:    { doc_count: 0,   c: { value: total } },
        total:   { doc_count: 326, v: { value: total } },
        social:  { doc_count: 0,   c: { value: total } },
        email:   { doc_count: 326, c: { value: total } },
        traffic: { doc_count: 0,   c: { value: total } }
      }
    }
  end

  before do
    stub_request(:get, search_url)
      .with(body: request.to_json)
      .to_return(status: 200, body: response.to_json, headers: { 'content-type' => 'application/json; charset=UTF-8' })

    allow_any_instance_of(FetchSiteStatisticsFromES).to(receive(:call)).and_call_original
  end

  it 'queries elastic to return the call count as total' do
    expect(service.call[:call]).to eql total
  end

  it 'queries elastic to return the call count as total' do
    expect(service.call[:total]).to eql total
  end

  it 'queries elastic to return the call count as total' do
    expect(service.call[:social]).to eql total
  end

  it 'queries elastic to return the call count as total' do
    expect(service.call[:email]).to eql total
  end

  it 'queries elastic to return the call count as total' do
    expect(service.call[:traffic]).to eql total
  end
end
