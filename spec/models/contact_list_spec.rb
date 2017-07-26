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
    it 'deletes contact list from default scope' do
      expect {
        contact_list.destroy
      }.to change { ContactList.count }.by(-1)
    end

    it 'soft deletes a contact list' do
      expect {
        contact_list.destroy
      }.to change { ContactList.only_deleted.count }
    end

    it 'destroys identity' do
      expect {
        contact_list.destroy
      }.to change { Identity.count }
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
