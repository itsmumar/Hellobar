shared_context 'service provider' do
  let(:list_id) { 4567456 }
  let(:contact_list) { create(:contact_list, :with_tags, list_id: list_id) }
  let(:provider) { ServiceProvider.new(identity, contact_list) }
  let(:adapter) { provider.adapter }

  let(:email) { 'example@email.com' }
  let(:first_name) { 'FirstName' }
  let(:last_name) { 'LastName' }
  let(:name) { "#{ first_name } #{ last_name }"}
end
