require 'spec_helper'

describe ServiceProviders::EmbedCodeProvider do
  let(:contact_list) { create(:contact_list, :embed_code) }

  let(:service_provider) do
    ServiceProviders::EmbedCodeProvider.new(contact_list: contact_list)
  end

  describe 'subscribe_params' do
    context 'names' do
      # Test a form that asks for (full) name only
      it 'sets names to blank strings if input is nil' do
        contact_list.data['embed_code'] = embed_code_file_for('mad_mimi_full_name')
        p = service_provider.subscribe_params('email@email.com', nil)
        expect(p['signup[name]']).to eq('')
      end

      it 'sets a single name param' do
        contact_list.data['embed_code'] = embed_code_file_for('mad_mimi_full_name')
        p = service_provider.subscribe_params('email@email.com', 'Michael Jordan')
        expect(p['signup[name]']).to eq('Michael Jordan')
      end

      # Test a form that asks for first name only
      it 'sets the first name param' do
        contact_list.data['embed_code'] = embed_code_file_for('mad_mimi_first_name')
        p = service_provider.subscribe_params('email@email.com', 'Michael Jordan')
        expect(p['signup[first_name]']).to eq('Michael')
      end

      # Test a form that asks for first and last name
      it 'sets the first and last name param' do
        contact_list.data['embed_code'] = embed_code_file_for('mad_mimi_first_and_last_name')
        p = service_provider.subscribe_params('email@email.com', 'Michael Jordan')
        expect(p['signup[first_name]']).to eq('Michael')
        expect(p['signup[last_name]']).to eq('Jordan')
      end
    end
  end
end
