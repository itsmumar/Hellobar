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
end
