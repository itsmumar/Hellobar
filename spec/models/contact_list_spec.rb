describe ContactList do
  let!(:contact_list) { create(:contact_list, :aweber) }

  describe 'as a valid object' do
    let(:identity) { build :identity, provider: 'webhooks' }
    let(:list) { build :contact_list, identity: identity, data: { 'webhook_url' => 'http://localhost/hook' } }

    it 'validates a webhook has a valid URL' do
      expect(list).to be_valid
    end

    context 'when url is empty' do
      let(:list) { build(:contact_list, identity: identity, data: { 'webhook_url' => '' }) }

      it 'is not valid' do
        expect(list).not_to be_valid
      end
    end

    context 'when wrong protocol' do
      let(:list) { build(:contact_list, identity: identity, data: { 'webhook_url' => 'ftp://localhost' }) }

      it 'is not valid' do
        expect(list).not_to be_valid
      end
    end

    context 'when host does not exist' do
      let(:list) { build(:contact_list, identity: identity, data: { 'webhook_url' => 'http://foobarbaz' }) }

      it 'is not valid' do
        expect(list).not_to be_valid
      end
    end
  end

  describe 'site_elements_count' do
    let(:num) { 3 }

    it 'runs the number of site_elements_count' do
      num.times { |_| contact_list.site_elements << create(:site_element) }
      expect(contact_list.site_elements_count).to eq(3)
    end
  end

  describe '#destroy' do
    it 'marks the record as deleted', :freeze do
      expect(contact_list.deleted_at).to be_nil

      contact_list.destroy

      expect(contact_list.deleted_at).to eq Time.current

      expect {
        ContactList.find(contact_list.id)
      }.to raise_exception ActiveRecord::RecordNotFound
    end

    it 'destroys the identity and nullifies identity_id' do
      identity = contact_list.identity

      contact_list.destroy

      expect(identity).to be_destroyed
      expect(contact_list.reload.identity_id).to be_nil
    end
  end

  describe '#subscribers' do
    it 'gets subscribers from the data API' do
      expect(FetchContacts).to receive_service_call
        .and_return([{ email: 'person@gmail.com', name: 'Per Son', subscribed_at: Time.zone.at(123456789) }])

      expect(contact_list.subscribers)
        .to eql [{ email: 'person@gmail.com', name: 'Per Son', subscribed_at: Time.zone.at(123456789) }]
    end

    it 'defaults to [] if data API returns nil' do
      expect(FetchContacts).to receive_service_call.and_return([])
      expect(contact_list.subscribers).to be_empty
    end

    it 'sends a limit to the data api if specified' do
      expect(FetchContacts).to receive_service_call.with(contact_list, limit: 100)
      contact_list.subscribers(100)
    end
  end

  describe '#data' do
    it 'drops nil values in data' do
      contact_list.data = { 'remote_name' => '', 'remote_id' => 1 }
      contact_list.identity = nil
      contact_list.save
      expect(contact_list.data['remote_name']).to be_nil
    end
  end
end

describe ContactList, 'embed code' do
  context 'invalid' do
    subject { build(:contact_list, :embed_code_invalid) }

    it { expect(subject).to be_invalid }
  end

  context 'valid' do
    subject { build(:contact_list, :embed_code_form) }

    it { expect(subject).to be_valid }
  end
end

describe ContactList, '#tags' do
  it 'returns an empty array when no tags have been saved' do
    contact_list = ContactList.new

    expect(contact_list.tags).to eql([])
  end

  it 'returns the tags that have been already saved' do
    contact_list = ContactList.new data: { 'tags' => %w[1 2 3] }

    expect(contact_list.tags).to eql(%w[1 2 3])
  end
end
