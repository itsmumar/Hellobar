require 'spec_helper'

CY_MAD_MIMI_EMBED_CODE = '<html><body><iframe><form>Here I am</form></iframe></body></html>'.freeze

require 'rake'
load 'lib/tasks/contact_list.rake'

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

  it 'should call sync_one!' do
    expect_any_instance_of(ContactList).to receive(:sync_one!).with('test.testerson@example.com', 'Test Testerson')
    perform!
  end

  it 'should require an email' do
    expect_any_instance_of(ContactList).not_to receive(:sync_one!)
    user[:email] = nil
    expect { perform! }.to raise_error, 'Cannot sync without email present'
  end

  it 'should require a contact_list_id' do
    expect_any_instance_of(ContactList).not_to receive(:sync_one!)
    expect { perform!(nil) }.to raise_error ActiveRecord::RecordNotFound, "Couldn't find ContactList without an ID"
  end

  it 'should not require a name' do
    expect_any_instance_of(ContactList).to receive(:sync_one!).with('test.testerson@example.com', nil)
    user[:name] = nil
    perform!
  end

  private

  def perform!(contact_list_id = contact_list.id, email = user[:email], name = user[:name])
    subject.invoke(contact_list_id, email, name)
    contact_list.reload
  end
end

describe 'contact_list:sync_all!' do
  include_context 'rake'

  let(:embed_code) { CY_MAD_MIMI_EMBED_CODE }
  let(:contact_list) do
    create(:contact_list, :embed_code).tap do |l|
      l.data['embed_code'] = embed_code
      l.save!
    end
  end

  it 'should call sync_all!' do
    expect_any_instance_of(ContactList).to receive(:sync_all!)
    perform!
  end

  def perform!(contact_list_id = contact_list.id)
    subject.invoke(contact_list_id)
    contact_list.reload
  end
end
