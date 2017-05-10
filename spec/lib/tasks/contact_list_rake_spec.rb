CY_MAD_MIMI_EMBED_CODE = '<html><body><iframe><form>Here I am</form></iframe></body></html>'.freeze

describe 'contact_list:sync_one' do
  include_context 'rake'

  let(:embed_code) { CY_MAD_MIMI_EMBED_CODE }
  let(:user) { { email: 'test.testerson@example.com', name: 'Test Testerson' } }
  let(:contact_list) do
    create(:contact_list, :embed_code).tap do |l|
      l.data['embed_code'] = embed_code
      l.save!
    end
  end

  before { allow(ContactList).to receive(:find).with(contact_list.id).and_return(contact_list) }

  it 'calls sync_one!' do
    expect(contact_list).to receive(:sync_one!).with('test.testerson@example.com', 'Test Testerson')
    perform!
  end

  it 'requires an email' do
    expect(contact_list).not_to receive(:sync_one!)
    user[:email] = nil
    expect { perform! }.to raise_error 'Cannot sync without email present'
  end

  it 'requires a contact_list_id' do
    allow(ContactList).to receive(:find).with(nil).and_call_original
    expect(contact_list).not_to receive(:sync_one!)
    expect { perform!(nil) }.to raise_error ActiveRecord::RecordNotFound, "Couldn't find ContactList without an ID"
  end

  it 'does not require a name' do
    expect(contact_list).to receive(:sync_one!).with('test.testerson@example.com', nil)
    user[:name] = nil
    perform!
  end

  it 'accepts custom fields' do
    expect(contact_list).to receive(:sync_one!).with('test.testerson@example.com', 'Name,phone,gender')
    user[:name] = 'Name,phone,gender'
    perform!
  end

  private

  def perform!(contact_list_id = contact_list.id, email = user[:email], name = user[:name])
    task.invoke(contact_list_id, email, name)
    contact_list.reload
  end
end

describe 'contact_list:sync_all!' do
  include_context 'rake'

  before { allow(ContactList).to receive(:find).with(contact_list.id).and_return(contact_list) }

  let(:embed_code) { CY_MAD_MIMI_EMBED_CODE }
  let(:contact_list) do
    create(:contact_list, :embed_code).tap do |l|
      l.data['embed_code'] = embed_code
      l.save!
    end
  end

  it 'should call sync_all!' do
    expect(contact_list).to receive(:sync_all!)
    perform!
  end

  def perform!(contact_list_id = contact_list.id)
    task.invoke(contact_list_id)
    contact_list.reload
  end
end
