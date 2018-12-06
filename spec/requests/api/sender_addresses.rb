describe 'api/sender_addresses requests' do
  let(:site) { create :site }
  let(:user) { create :user, site: site }
  let(:sender_address) { create :sender_address, site_id: site.id }
  let(:headers) { api_headers_for_user(user) }
  let(:params) { Hash[format: :json] }

  describe 'POST #create' do
    let(:site_id) { site.id }
    let(:address_one) { '221 Maple Street' }
    let(:address_two) { 'Unit F' }
    let(:city) { 'San Diego' }
    let(:state) { 'CA' }
    let(:postal_code) { '92103' }
    let(:country) { 'US' }
    let(:sender_address_params) do
      {
        site_id: site.id,
        address_one: address_one,
        address_two: address_two,
        city: city,
        state: state,
        postal_code: postal_code,
        country: country
      }
    end

    context 'creating a new sender address' do
      it 'responds with success' do
        post api_site_sender_addresses_path(site),
          params.merge(sender_address: sender_address_params),
          headers

        expect(response).to be_successful
        expect(response.code.to_i).to eql 200

        expect(json[:address_one]).to eql address_one
        expect(json[:address_two]).to eql address_two
        expect(json[:city]).to eql city
        expect(json[:state]).to eql state
        expect(json[:postal_code]).to eql postal_code
        expect(json[:country]).to eql country
      end
    end

    context 'editing a sender address' do
      let(:updated_address_params) do
        {
          site_id: site.id,
          address_one: '555 State St',
          address_two: address_two,
          city: city,
          state: 'NY',
          postal_code: postal_code,
          country: country
        }
      end

      it 'updates the sender address' do
        post api_site_sender_addresses_path(sender_address.id),
          params.merge(sender_address: updated_address_params),
          headers

        expect(response).to be_successful
        expect(response.code.to_i).to eql 200

        expect(json[:address_one]).to eql '555 State St'
        expect(json[:state]).to eql 'NY'
      end
    end
  end

  describe 'GET #index' do
    context 'getting a site sender address' do
      let(:site) { create :site }
      let(:user) { create :user, site: site }
      let(:sender_address) { create :sender_address, site_id: site.id }
      let(:headers) { api_headers_for_user(user) }
      let(:params) { Hash[format: :json] }
      let(:site_id) { site.id }
      let(:address_one) { '221 Maple Street' }
      let(:address_two) { 'Unit F' }
      let(:city) { 'San Diego' }
      let(:state) { 'CA' }
      let(:postal_code) { '92103' }
      let(:country) { 'US' }
      let(:site_id_params) do
        { site_id: site.id }
      end
      let(:sender_address_params) do
        {
          site_id: site.id,
          address_one: address_one,
          address_two: address_two,
          city: city,
          state: state,
          postal_code: postal_code,
          country: country
        }
      end

      before do
        post api_site_sender_addresses_path(site),
          params.merge(sender_address: sender_address_params),
          headers
      end

      it 'returns the site address associated with a site' do
        get api_site_sender_addresses_path(site),
          params.merge(sender_address: site_id_params),
          headers

        expect(response).to be_successful
        expect(response.code.to_i).to eql 200

        expect(json[:address_one]).to eql '221 Maple Street'
      end
    end
  end
end
