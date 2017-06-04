describe ServiceProviders::GetResponseApi do
  it 'raises an error if no identity is provided' do
    expect { ServiceProviders::GetResponseApi.new }
      .to raise_error 'Must provide an identity through the arguments'
  end

  it 'raises error if identity is missing api key' do
    identity = Identity.new site_id: 1, provider: 'get_response_api'
    expect { ServiceProviders::GetResponseApi.new(identity: identity) }
      .to raise_error 'Identity does not have a stored GetResponse API key'
  end

  context 'remote requests' do
    let(:campaign_id) { 1122 }
    let(:contact_id) { 'contactId' }
    let(:name) { 'Bob' }
    let(:email) { 'bobloblaw@lawblog.com' }
    let(:tag_id) { 'tagId' }
    let(:tag_name) { 'new_lead' }
    let(:identity) { Identity.new site_id: 1, provider: 'get_response_api', api_key: 'my_cool_api_key' }
    let(:get_respone_api) { ServiceProviders::GetResponseApi.new(identity: identity) }
    let(:client) { Faraday.new }
    let(:success_body) {}
    let(:success_response) { double :response, success?: true, body: [{ campaignId: campaign_id, name: 'myCoolList' }].to_json }
    let(:tags_success_response) { double :response, success?: true, body: [{ tagId: tag_id, name: tag_name }].to_json }
    let(:failure_response) do
      double :response,
        success?: false,
        status: 500,
        body: { codeDescription: 'things went really bad' }.to_json
    end

    before do
      allow(Faraday).to receive(:new).and_return(client)
    end

    context '#lists' do
      it 'returns hash array of hashes of ids and names' do
        allow(client).to receive(:get).and_return(success_response)
        expect(get_respone_api.lists).to eq([{ 'id' => campaign_id, 'name' => 'myCoolList' }])
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
        expect(get_respone_api)
          .to receive(:log)
          .with("getting lists returned 'things went really bad' with the code 500")
        expect { get_respone_api.lists }.to raise_error(RuntimeError)
      end
    end

    context '#tags' do
      it 'returns hash array of hashes of ids and names' do
        allow(client).to receive(:get).and_return(tags_success_response)
        expect(get_respone_api.tags).to eq([{ 'id' => tag_id, 'name' => tag_name }])
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
        expect(get_respone_api)
          .to receive(:log)
          .with("getting lists returned 'things went really bad' with the code 500")
        expect { get_respone_api.tags }.to raise_error(RuntimeError)
      end
    end

    context '#subscribe' do
      let(:successful_response) { double(:response, success?: true) }
      let(:request_body) do
        {
          name: name,
          email: email,
          campaign: {
            campaignId: campaign_id
          }
        }
      end
      let(:contact_list) { create :contact_list, :with_tags }

      it 'submits name and email address if both are present' do
        allow(client).to receive(:post).with('contacts', request_body)
          .and_return successful_response

        get_respone_api.subscribe(campaign_id, email, name)
      end

      it 'does not submit name if no name is present' do
        expect(client).to receive(:post).with('contacts', request_body.except(:name))
          .and_return successful_response

        get_respone_api.subscribe(campaign_id, email)
      end

      it 'assign selected tags to the recently/previously added and confirmed contact' do
        api = ServiceProviders::GetResponseApi.new(identity: identity, contact_list: contact_list)

        latest_contacts_successful_response =
          double :response,
            success?: true,
            body: [{ contactId: contact_id, email: email }].to_json

        tags = contact_list.tags.map { |tag| { tagId: tag } }

        expect(contact_list).to receive(:subscribers)
          .and_return([{ name: 'Bob Lob', email: 'bobloblaw@lawblog.com' },
                       { name: 'Lob Bob', email: 'blob@lawblog.com' }])
        expect(api).to receive(:find_union)
          .and_return([{ 'contactId' => 'contactId', 'email' => 'bobloblaw@lawblog.com' }])
        expect(client).to receive(:post).with('contacts', request_body)
          .and_return successful_response
        expect(client).to receive(:get)
          .and_return latest_contacts_successful_response
        expect(client).to receive(:post).with("contacts/#{ contact_id }", tags: tags)
          .and_return latest_contacts_successful_response

        api.subscribe(campaign_id, email, name)
      end

      it 'logs parsed error message in the event of failed request' do
        allow(client).to receive(:post).and_return(failure_response)

        expect(get_respone_api)
          .to receive(:log)
          .with("sync error #{ email } sync returned 'things went really bad' with the code 500")

        get_respone_api.subscribe(campaign_id, email)
      end

      it 'handles time out' do
        allow(client).to receive(:post).and_raise(Faraday::TimeoutError)

        expect(get_respone_api)
          .to receive(:log)
          .with('sync timed out')

        get_respone_api.subscribe(campaign_id, email)
      end

      context 'when contact_list.data[cycle_day] present' do
        let(:contact_list) { build(:contact_list, data: { 'cycle_day' => '1' }) }
        let(:get_respone_api) { ServiceProviders::GetResponseApi.new(identity: identity, contact_list: contact_list) }

        it 'sends dayOfCycle param' do
          request_body = {
            email: 'bobloblaw@lawblog.com',
            campaign: { campaignId: 1122 },
            dayOfCycle: '1'
          }
          expect(client).to receive(:post).with('contacts', request_body)
          get_respone_api.subscribe(campaign_id, email)
        end
      end
    end
  end
end
