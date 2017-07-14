describe Hello::DataAPI do
  def for_comparison(results)
    {}.tap do |r|
      results.each { |k, v| r[k] = v.to_a }
    end
  end

  describe '.lifetime_totals_by_type' do
    let(:site) { create(:site, :with_rule) }
    let(:call_element) { create(:site_element, :click_to_call, rule: site.rules.last) }

    it 'rolls up lifetime totals by site element type' do
      allow(Hello::DataAPI).to receive(:lifetime_totals)
        .and_return(
          create(:site_element, :traffic, site: site).id.to_s => [[2, 1]],
          create(:site_element, :email, site: site).id.to_s => [[4, 3]],
          create(:site_element, :twitter, site: site).id.to_s => [[6, 5]],
          create(:site_element, :facebook, site: site).id.to_s => [[8, 7]],
          call_element.id.to_s => [[5, 2]]
        )

      result = Hello::DataAPI.lifetime_totals_by_type(site, site.site_elements)

      expect(for_comparison(result))
        .to eq(
          total: [[25, 18]],
          traffic: [[2, 1]],
          email: [[4, 3]],
          social: [[14, 12]],
          call: [[5, 2]]
        )
    end

    it 'when site elements have different amounts of data, use all of it' do
      allow(Hello::DataAPI).to receive(:lifetime_totals)
        .and_return(
          create(:site_element, :traffic, site: site).id.to_s => [[2, 1]],
          create(:site_element, :email, site: site).id.to_s => [[4, 3]],
          create(:site_element, :twitter, site: site).id.to_s => [[3, 1], [6, 5]],
          create(:site_element, :facebook, site: site).id.to_s => [[8, 7]],
          call_element.id.to_s => [[2, 1], [5, 2]]
        )

      result = Hello::DataAPI.lifetime_totals_by_type(site, site.site_elements)

      expect(for_comparison(result))
        .to eq(
          total: [[5, 2], [25, 18]],
          traffic: [[2, 1]],
          email: [[4, 3]],
          social: [[3, 1], [14, 12]],
          call: [[2, 1], [5, 2]]
        )
    end

    it "returns empty totals if there's no data" do
      allow(Hello::DataAPI).to receive(:lifetime_totals).and_return({})

      result = Hello::DataAPI.lifetime_totals_by_type(site, site.site_elements)
      expect(for_comparison(result)).to eq(total: [], traffic: [], email: [], social: [], call: [])
    end
  end

  describe '.contact_list_totals' do
    let(:site) { create :site }
    let(:list_size) { Hello::DataAPI::API_MAX_SLICE + 1 }
    let(:contact_lists) { create_list :contact_list, list_size, site: site }

    it 'slices up contact lists ids into multiple requests based on API_MAX_SLICE' do
      expect(Hello::DataAPI).to receive(:get).exactly(:twice) {}

      Hello::DataAPI.contact_list_totals site, contact_lists
    end

    it 'merges the results from multiple API requests into a single Hash' do
      stats_request_one = Hash[contact_lists.first.id => 7]
      stats_request_two = Hash[contact_lists.last.id => 6]
      stats = stats_request_one.merge stats_request_two

      allow(Hello::DataAPI).to receive(:get)
        .and_return stats_request_one, stats_request_two

      result = Hello::DataAPI.contact_list_totals site, contact_lists

      expect(result).to eq stats
    end
  end

  describe '.contacts', :freeze do
    before do
      allow(Hello::DataAPIHelper).to receive(:generate_signature).and_return('signature')
    end

    let(:contact_list) { create :contact_list }
    let(:limit) { 5 }
    let(:params) do
      {
        'l' => limit,
        'd' => 0,
        't' => Time.current.to_i,
        's' => 'signature'
      }
    end

    let(:response_body) { [['person100@gmail.com', 'person name', 1388534400]] }

    let!(:request) do
      stub_request(:get, %r{http://mock-hi.hellobar.com/e/\w+/\w+})
        .with(query: params.to_query)
        .to_return(status: 200, body: response_body.to_json)
    end

    it 'returns an array of contacts' do
      expect(Hello::DataAPI.contacts(contact_list, limit)).to eql response_body
    end
  end
end
