describe ServiceProviders::Adapters::MyEmma do
  define_urls(
    form: 'https://madmimi.com/signups/103242/iframe',
    subscribe: 'https://madmimi.com/signups/iframe_subscribe/103242'
  )

  let(:identity) { double('identity', provider: 'my_emma') }
  include_examples 'service provider'
  let(:contact_list) { create(:contact_list, :embed_iframe) }

  allow_request :get, :form

  describe '#initialize' do
    it 'initializes Faraday::Connection' do
      expect(adapter.client).to be_a Faraday::Connection
    end
  end

  describe '#subscribe' do
    body = {
      'authenticity_token' => 'RhtvXkXEbMNc+JIDw16AD6YHSfHjN1Wa75x6rlCybYoRNynWjyGWthSGFATjYnwHSK4dUYIPHj9VpeTqNJ2z8g==',
      'beacon' => '',
      'd5ae1d9aa05b39486b92cf62fab5a5bd' => '',
      'signup' => { 'email' => 'example@email.com', 'name' => 'FirstName LastName' },
      'spinner' => '7c0442e4f7d49abfa03fe6f1bd699939f6f3f4bfc45483705bd50cecf2986d277b6ec32ab9e4172235eb5929ba035fee',
      'utf8' => '✓'
    }

    allow_request :post, :subscribe, body: body do |stub|
      let(:subscribe_request) { stub }
    end

    it 'sends subscribe request' do
      provider.subscribe(list_id, email: email, name: name)
      expect(subscribe_request).to have_been_made
    end
  end
end
