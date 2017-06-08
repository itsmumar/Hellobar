describe ContactList do
  let!(:contact_list) { create(:contact_list, :aweber) }

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
