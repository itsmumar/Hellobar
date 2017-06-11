describe ServiceProviders::ConstantContact do
  let(:credentials) { { 'token' => '15319244-a98b-45a2-814b-704a632095e7' } }
  let(:identity) { Identity.new(provider: 'constantcontact', extra: {}, credentials: credentials) }
  let(:service_provider) { identity.service_provider }
  let(:client) { service_provider.instance_variable_get(:@client) }

  before { Settings.identity_providers['constantcontact']['app_key'] = 'constantcontact-app-key' }

  describe 'lists' do
    it 'returns available lists', :vcr do
      expect(service_provider.lists).to eql [
        { 'id' => '1552534540', 'name' => 'General Interest' },
        { 'id' => '1139133042', 'name' => 'Test_hellobar' }
      ]
    end
  end
end
