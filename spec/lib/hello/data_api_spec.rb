require 'spec_helper'

describe Hello::DataAPI do
  fixtures :all

  def for_comparison(results)
    {}.tap do |r|
      results.each { |k, v| r[k] = v.to_a }
    end
  end

  describe '.lifetime_totals_by_type' do
    let(:site) { sites(:zombo) }
    let(:call_element) { create(:site_element, :click_to_call, rule: site.rules.last) }

    it 'rolls up lifetime totals by site element type' do
      allow(Hello::DataAPI).to receive(:lifetime_totals)
        .and_return(
          site_elements(:zombo_traffic).id.to_s => [[2, 1]],
          site_elements(:zombo_email).id.to_s => [[4, 3]],
          site_elements(:zombo_twitter).id.to_s => [[6, 5]],
          site_elements(:zombo_facebook).id.to_s => [[8, 7]],
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
          site_elements(:zombo_traffic).id.to_s => [[2, 1]],
          site_elements(:zombo_email).id.to_s => [[4, 3]],
          site_elements(:zombo_twitter).id.to_s => [[3, 1], [6, 5]],
          site_elements(:zombo_facebook).id.to_s => [[8, 7]],
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
      expect(Hello::DataAPI).to receive(:get).exactly(:twice).and_return {}

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

  describe '.get_contacts' do
    let(:contact_list) { create :contact_list }
    let(:id) { contact_list.id }
    let(:site_id) { contact_list.site_id }
    let(:read_key) { contact_list.site.read_key }
    let(:limit) { 5 }
    let(:get_contacts) do
      VCR.use_cassette('contact_list/get_contacts') do
        Hello::DataAPI.get_contacts(contact_list, limit)
      end
    end

    before(:each) do
      allow(Hello::DataAPIHelper::RequestParts).to receive(:get_contacts)
        .with(site_id, id, read_key, limit, nil)
        .and_return(['/e/GIHiEM2QmS/qvpJXYvS6',
                     { 'l' => 5, 'd' => 1_481_207_259, 't' => 1_482_071_362,
                       's' => '2981a1d7a8745e492943f561d4a6aef30de' \
                             '889af48cd4c32e6c0a4b56abf400e30f4f8' \
                             '115fb091130f2e5925106a6e50485f67e73' \
                             'a3ffe9f0260cd1cd80c1c2c' }])
    end

    it 'should cache `Hello::DataAPIHelper::RequestParts.get_contacts`' do
      expect(Hello::DataAPIHelper::RequestParts).to receive(:get_contacts)
        .with(site_id, id, read_key, limit, nil).once

      2.times { get_contacts }
    end

    it 'should return 5 contact records' do
      expect(get_contacts.count).to eq(limit)
    end
  end
end
