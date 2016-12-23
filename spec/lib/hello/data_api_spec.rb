require "spec_helper"

describe  Hello::DataAPI do
  fixtures :all

  def for_comparison(results)
    {}.tap do |r|
      results.each { |k, v| r[k] = v.to_a }
    end
  end

  describe ".lifetime_totals_by_type" do
    let(:site) { sites(:zombo) }
    let(:call_element) { create(:site_element, :click_to_call, rule: site.rules.last) }

    it "rolls up lifetime totals by site element type" do
      allow(Hello::DataAPI).to receive(:lifetime_totals).and_return({
        site_elements(:zombo_traffic).id.to_s =>  [[2, 1]],
        site_elements(:zombo_email).id.to_s =>    [[4, 3]],
        site_elements(:zombo_twitter).id.to_s =>  [[6, 5]],
        site_elements(:zombo_facebook).id.to_s => [[8, 7]],
        call_element.id.to_s => [[5,2]]
      })

      result = Hello::DataAPI.lifetime_totals_by_type(site, site.site_elements)

      expect(for_comparison(result)).to eq({
        total: [[25, 18]],
        traffic: [[2, 1]],
        email: [[4, 3]],
        social: [[14, 12]],
        call: [[5,2]]
      })
    end

    it "when site elements have different amounts of data, use all of it" do
      allow(Hello::DataAPI).to receive(:lifetime_totals).and_return({
        site_elements(:zombo_traffic).id.to_s =>  [[2, 1]],
        site_elements(:zombo_email).id.to_s =>    [[4, 3]],
        site_elements(:zombo_twitter).id.to_s =>  [[3, 1], [6, 5]],
        site_elements(:zombo_facebook).id.to_s => [[8, 7]],
        call_element.id.to_s => [[2,1], [5,2]]
      })

      result = Hello::DataAPI.lifetime_totals_by_type(site, site.site_elements)

      expect(for_comparison(result)).to eq({
        total: [[5, 2], [25, 18]],
        traffic: [[2, 1]],
        email: [[4, 3]],
        social: [[3, 1], [14, 12]],
        call: [[2,1], [5,2]]
      })
    end

    it "returns empty totals if there's no data" do
      allow(Hello::DataAPI).to receive(:lifetime_totals).and_return({})

      result = Hello::DataAPI.lifetime_totals_by_type(site, site.site_elements)
      expect(for_comparison(result)).to eq({total: [], traffic: [], email: [], social: [], call: []})
    end
  end

  describe '.get_contacts' do
    let(:contact_list) { create :contact_list }
    let(:id) { contact_list.id }
    let(:site_id) { contact_list.site_id }
    let(:read_key) { contact_list.site.read_key }
    let(:limit) { 5 }

    it 'passes 0 to DynamoDB for the `from_timestamp` param as default' do
      # TODO this needs a separate VCR casette
      allow(Hello::DataAPI).to receive(:get)

      # Weird Rails' cache behaviour, it would not yield the block in spec runs
      allow(Rails.cache).to receive(:fetch).and_yield

      expect(Hello::DataAPIHelper::RequestParts).to receive(:get_contacts)
        .with(site_id, id, read_key, limit, 0)

      Hello::DataAPI.get_contacts(contact_list, limit)
    end
  end
end
