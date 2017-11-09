describe IntercomGateway do
  let(:intercom) { IntercomGateway.new }
  let(:url) { 'https://api.intercom.io' }
  let(:user_id) { 66 }
  let(:intercom_id) { 'id' }
  let(:user_attributes) { Hash['type' => 'user', 'id' => intercom_id, 'user_id' => user_id] }

  describe '#track' do
    it 'sends track event request to Intercom' do
      stub_request(:post, "#{ url }/events")

      event = {
        event_name: 'name',
        user_id: user_id
      }

      intercom.track event
    end
  end

  describe '#create_user' do
    it 'sends create user request to Intercom' do
      stub_request(:post, "#{ url }/users")

      user = instance_double User, id: user_id, email: 'me@example.org'

      intercom.create_user user
    end
  end

  describe '#tag_users' do
    let(:tag) { 'tag' }

    it 'sends tags request to Intercom' do
      stub_request(:post, "#{ url }/tags")

      user = instance_double User, id: user_id

      intercom.tag_users tag, [user]
    end

    it 'does nothing if there are no users to tag' do
      expect_any_instance_of(Intercom::Client).not_to receive :tags

      intercom.tag_users tag, []
    end
  end

  describe '#find_user' do
    it 'sends GET request to Intercom' do
      stub_request(:get, "#{ url }/users?user_id=#{ user_id }")
        .to_return status: 200, body: user_attributes.to_json

      intercom_user = intercom.find_user user_id

      expect(intercom_user).to be_an Intercom::User
      expect(intercom_user.user_id).to eql user_id
    end

    it 'returns `nil` if user is not found at Intercom' do
      stub_request(:get, "#{ url }/users?user_id=#{ user_id }")
        .to_return status: 404

      expect(intercom.find_user(user_id)).to eq nil
    end
  end

  describe '#delete_user' do
    it 'sends users.delete request to Intercom' do
      stub_request(:get, "#{ url }/users?user_id=#{ user_id }")
        .to_return status: 200, body: user_attributes.to_json

      stub_request(:delete, "#{ url }/users/#{ intercom_id }")

      intercom.delete_user user_id
    end

    it 'does not send delete request to Intercom if user is not found' do
      stub_request(:get, "#{ url }/users?user_id=#{ user_id }")
        .to_return status: 404

      intercom.delete_user user_id
    end
  end
end
