shared_context 'service provider' do
  let(:contact_list) { create(:contact_list, :with_tags) }
  let(:provider) { ServiceProviders::Provider.new(identity, contact_list) }
  let(:adapter) { provider.adapter }

  let(:email) { 'example@email.com' }
  let(:name) { 'FirstName LastName' }
  let(:first_name) { 'FirstName' }
  let(:last_name) { 'LastName' }

  let(:list_id) { 4567456 }
end
