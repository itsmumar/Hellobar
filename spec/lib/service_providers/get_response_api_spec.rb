require 'spec_helper'

describe ServiceProviders::GetResponseApi do
  it 'raises an error if no identity is provided' do
    expect{ServiceProviders::GetResponseApi.new}.to raise_error('Must provide an identity through the arguments')
  end

  it 'raises error if identity is missing api key' do
    identity = Identity.new site_id: 1, provider: 'get_response_api'
    expect{ServiceProviders::GetResponseApi.new(identity: identity)}.to raise_error('Identity does not have a stored GetResponse API key')
  end

  context 'remote requests' do
    let(:identity) {Identity.new site_id: 1, provider: 'get_response_api', api_key: 'my_cool_api_key'}
    let(:get_respone_api) {ServiceProviders::GetResponseApi.new(identity: identity)}
    let(:client) {Faraday.new}
    let(:success_body) {}
    let(:success_response) {double :response, success?: true, body: [{campaignId: 1122, name: 'myCoolList'}].to_json}
    let(:tags_success_response) {double :response, success?: true, body: [{tagId: 1122, name: 'myHotTag'}].to_json}
    let(:failure_response) {
      double :response,
      success?: false,
      status: 500,
      body: {codeDescription: 'things went really bad'}.to_json
    }

    before do
      allow(Faraday).to receive(:new).and_return(client)
    end

    context '#lists' do
      it 'returns hash array of hashes of ids and names' do
        allow(client).to receive(:get).and_return(success_response)
        expect(get_respone_api.lists).to eq([{'id' => 1122, 'name' => 'myCoolList'}])
      end

      it 'raise exception when time out' do
        allow(client).to receive(:get).and_raise(Faraday::TimeoutError)
        expect { get_respone_api.lists }.to raise_error(Faraday::TimeoutError)
      end

      it 'raise exception when invalid credentials' do
        allow(client).to receive(:get).and_return(failure_response)
        expect { get_respone_api.lists }.to raise_error('things went really bad')
      end

      it 'logs parsed error message in the event of failed request' do
        allow(client).to receive(:get).and_return(failure_response)
        expect(get_respone_api).
          to receive(:log).
          with("getting lists returned 'things went really bad' with the code 500")
        expect { get_respone_api.lists }.to raise_error(RuntimeError)
      end
    end

    context "#tags" do
      it 'returns hash array of hashes of ids and names' do
        allow(client).to receive(:get).and_return(tags_success_response)
        expect(get_respone_api.tags).to eq([{'id' => 1122, 'name' => 'myHotTag'}])
      end

      it 'raise exception when time out' do
        allow(client).to receive(:get).and_raise(Faraday::TimeoutError)
        expect { get_respone_api.tags }.to raise_error(Faraday::TimeoutError)
      end

      it 'raise exception when invalid credentials' do
        allow(client).to receive(:get).and_return(failure_response)
        expect { get_respone_api.tags }.to raise_error('things went really bad')
      end

      it 'logs parsed error message in the event of failed request' do
        allow(client).to receive(:get).and_return(failure_response)
        expect(get_respone_api).
          to receive(:log).
          with("getting lists returned 'things went really bad' with the code 500")
        expect { get_respone_api.tags }.to raise_error(RuntimeError)
      end
    end

    context '#subscribe' do
      it 'submits email address as name if name is not present' do
        double_request = double(:request, url: true)
        double_response = double(:response, success?: true)

        expect(double_request).
          to receive(:body=).
          with({name: "Bob", email: "bobloblaw@lawblog.com", campaign: {campaignId: 1122}, :tags=>[]}).
          and_return(double_response)

        allow(client).to receive(:post).and_yield(double_request)
        get_respone_api.subscribe(1122, 'bobloblaw@lawblog.com', 'Bob')
      end

      it 'does not submit email address as name if name is present' do
        double_request = double(:request, url: true)
        double_response = double(:response, success?: true)

        expect(double_request).
          to receive(:body=).
          with({name: "bobloblaw@lawblog.com", email: "bobloblaw@lawblog.com", campaign: {campaignId: 1122}, :tags=>[]}).
          and_return(double_response)

        allow(client).to receive(:post).and_yield(double_request)
        get_respone_api.subscribe(1122, 'bobloblaw@lawblog.com')
      end

      it 'logs parsed error message in the event of failed request' do
        allow(client).to receive(:post).and_return(failure_response)
        expect(get_respone_api).
          to receive(:log).
          with("sync error bobloblaw@lawblog.com sync returned 'things went really bad' with the code 500")
        get_respone_api.subscribe(1122, 'bobloblaw@lawblog.com')
      end

      it 'handles time out' do
        allow(client).to receive(:post).and_raise(Faraday::TimeoutError)
        expect(get_respone_api).
          to receive(:log).
          with("sync timed out")
        get_respone_api.subscribe(1122, 'bobloblaw@lawblog.com')
      end
    end
  end
end
