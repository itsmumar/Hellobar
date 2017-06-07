describe ContactList do
  let(:site) { create(:site) }
  let(:provider) { 'mailchimp' }
  let(:identity) { Identity.new(site: site, provider: provider) }
  let(:contact_list) { create(:contact_list, identity: identity) }
  let(:service_provider) { contact_list.service_provider }

  before do
    allow(Hello::DataAPI).to receive(:contacts).and_return([
      ['test1@hellobar.com', '', 1384807897],
      ['test2@hellobar.com', '', 1384807898]
    ])
  end

  describe 'as a valid object' do
    it 'validates a webhook has a valid URL' do
      list = build(:contact_list, data: { 'webhook_url' => 'url' })

      list.valid?

      expect(list.errors[:base]).to include('webhook URL is invalid')
    end
  end

  describe 'associated identity' do
    it 'should use #provider on creation to find the correct identity' do
      identity = create(:identity)
      list = build(:contact_list, site: identity.site, provider_token: 'mailchimp')

      expect { list.valid? }.to change { list.identity }.from(nil).to(identity)
    end

    it 'should use #provider on edit to find the correct identity' do
      constantcontact = create(:identity, :constantcontact)
      list = create(:contact_list, :mailchimp, site: constantcontact.site)
      list.provider_token = 'constantcontact'
      list.save
      expect(list.identity).to eql constantcontact
    end

    it 'should not be valid if #provider does not match an existing identity' do
      list = create(:contact_list)
      list.provider_token = 'notanesp'
      list.identity = nil

      expect(list).not_to be_valid
      expect(list.errors.messages[:provider]).to include('is not valid')
    end

    it 'should clear the identity if provider is "0"' do
      list = create(:contact_list, :mailchimp)
      expect(list.identity).not_to be_blank

      list.update_attributes(provider_token: '0')
      expect(list.identity).to be_blank
    end

    it 'should notify the old identity when the identity is updated' do
      list = create(:contact_list, :mailchimp)
      old_identity = list.identity
      expect(old_identity).to receive(:contact_lists_updated)
      allow(Identity).to receive(:find_by).and_return(old_identity)
      list.identity = create(:identity, :constantcontact)
      list.save
    end

    it 'should message the identity when the contact list is destroyed' do
      list = create(:contact_list, :mailchimp)
      old_identity = list.identity
      expect(old_identity).to receive(:contact_lists_updated)
      allow(Identity).to receive(:find_by).and_return(old_identity)
      list.destroy
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
  end

  describe '#subscribers' do
    it 'gets subscribers from the data API' do
      allow(Hello::DataAPI).to receive(:contacts).and_return([['person@gmail.com', 'Per Son', 123456789]])
      expect(contact_list.subscribers).to eql [{ email: 'person@gmail.com', name: 'Per Son', subscribed_at: Time.zone.at(123456789) }]
    end

    it 'defaults to [] if data API returns nil' do
      allow(Hello::DataAPI).to receive(:contacts).and_return(nil)
      expect(contact_list.subscribers).to be_empty
    end

    it 'sends a limit to the data api if specified' do
      expect(Hello::DataAPI).to receive(:contacts).with(contact_list, 100)
      contact_list.subscribers(100)
    end
  end

  describe '#num_subscribers' do
    it 'gets number of subscribers from the data API' do
      allow(Hello::DataAPI).to receive(:contact_list_totals).and_return(contact_list.id.to_s => 5)
      expect(contact_list.num_subscribers).to eq(5)
    end

    it 'defaults to 0 if data API returns nil' do
      allow(Hello::DataAPI).to receive(:contact_list_totals).and_return(nil)
      expect(contact_list.num_subscribers).to eq(0)
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
