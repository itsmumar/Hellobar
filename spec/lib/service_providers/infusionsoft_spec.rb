describe ServiceProviders::Infusionsoft do
  let(:identity) { Identity.new(provider: 'infusionsoft', api_key: 'test-api-key', extra: { app_url: 'test1.infusionsoft.com' }) }
  let(:service_provider) { identity.service_provider }
  let(:contact_list) { ContactList.new }

  before do
    allow(Infusionsoft).to receive(:contact_add_with_dup_check) { 1 }
  end

  describe '#tags' do
    it 'should make a call to Infusionsoft for their tags' do
      expect(Infusionsoft).to receive(:data_query) { [] }
      service_provider.tags
    end
  end

  describe '#subscribe' do
    let(:email) { 'test@test.com' }

    it 'calls contact_add_with_dup_check' do
      name = 'Gal Anonymous'
      first_name, last_name = name.split
      data = { Email: email, FirstName: first_name, LastName: last_name }
      service_provider.instance_variable_set(:@contact_list, contact_list)

      expect(Infusionsoft).to receive(:contact_add_with_dup_check).with(data, :Email)

      service_provider.subscribe(nil, email, name)
    end

    it 'passes empty strings if name is nil to contact_add_with_dup_check' do
      data = { Email: email, FirstName: '', LastName: '' }
      service_provider.instance_variable_set(:@contact_list, contact_list)

      expect(Infusionsoft).to receive(:contact_add_with_dup_check).with(data, :Email)

      service_provider.subscribe(nil, email, nil)
    end

    it 'passes all parts of the name to contact_add_with_dup_check' do
      name = 'Mr Gal The Third Son Anonymous'
      first_name = name.split[0..-2].join ' '
      last_name = name.split[-1]
      data = { Email: email, FirstName: first_name, LastName: last_name }
      service_provider.instance_variable_set(:@contact_list, contact_list)

      expect(Infusionsoft).to receive(:contact_add_with_dup_check).with(data, :Email)

      service_provider.subscribe(nil, email, name)
    end

    it 'tags the user with all of the tags when present' do
      contact_list.data = { 'tags' => %w[1 2 3] }
      service_provider.instance_variable_set(:@contact_list, contact_list)

      expect(Infusionsoft).to receive(:contact_add_to_group).exactly(3).times { nil }

      service_provider.subscribe(nil, email)
    end

    it 'does NOT tag the user when no tags are present' do
      service_provider.instance_variable_set(:@contact_list, contact_list)

      expect(Infusionsoft).to_not receive(:contact_add_to_group)

      service_provider.subscribe(nil, email)
    end
  end
end
