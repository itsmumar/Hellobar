describe ServiceProvider::Adapters::MadMimiForm do
  let(:defined_urls) do
    {
      form: 'https://madmimi.com/signups/103242/iframe',
      subscribe: 'https://madmimi.com/signups/iframe_subscribe/103242'
    }
  end

  include_context 'service provider'

  let(:contact_list) { create(:contact_list, :mad_mimi_form) }
  let(:identity) { create :identity, :mad_mimi_form, contact_lists: [contact_list] }

  before { allow_request :get, :form }

  describe '#initialize' do
    it 'initializes Faraday::Connection' do
      expect(adapter.client).to be_a Faraday::Connection
    end
  end

  describe '#subscribe' do
    let(:body) do
      {
        'authenticity_token' => 'RhtvXkXEbMNc+JIDw16AD6YHSfHjN1Wa75x6rlCybYoRNynWjyGWthSGFATjYnwHSK4dUYIPHj9VpeTqNJ2z8g==',
        'd5ae1d9aa05b39486b92cf62fab5a5bd' => '',
        'signup' => { 'email' => 'example@email.com', 'name' => 'FirstName LastName' },
        'spinner' => '7c0442e4f7d49abfa03fe6f1bd699939f6f3f4bfc45483705bd50cecf2986d277b6ec32ab9e4172235eb5929ba035fee',
        'utf8' => '✓'
      }
    end
    let!(:subscribe_request) { allow_request :post, :subscribe, body: body }

    it 'sends subscribe request' do
      provider.subscribe(email: email, name: name)
      expect(subscribe_request).to have_been_made
    end

    context 'when error is occured' do
      before { stub_request(:post, url_for_request(:subscribe)).and_return(status: 404, body: '{}') }

      it 'calls DestroyIdentity' do
        expect(DestroyIdentity).to receive_service_call.with(identity, notify_user: true)
        expect { provider.subscribe(email: email, name: name) }.not_to raise_error
      end
    end

    context 'when could not parse html' do
      it 'calls DestroyIdentity' do
        expect(DestroyIdentity).to receive_service_call.with(identity, notify_user: true)
        expect(ExtractEmbedForm)
          .to receive_service_call.and_raise ExtractEmbedForm::Error.new('test message')

        expect { provider.subscribe(email: email, name: name) }.not_to raise_error
      end
    end
  end
end
