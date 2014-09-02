require 'spec_helper'

CY_MAD_MIMI_EMBED_CODE = '<iframe src="https://madmimi.com/signups/103242/iframe" scrolling="no" frameborder="0" height="405" width="400"></iframe>'

require 'rake'
load 'lib/tasks/contact_list.rake'

describe "contact_list:sync_one" do
  fixtures :all
  include_context 'rake'

  let(:embed_code) { CY_MAD_MIMI_EMBED_CODE }
  let(:user) { { email: "test.testerson@example.com", name: "Test Testerson" } }
  let(:contact_list) do
    contact_lists(:embed_code).tap do |l|
      l.data['embed_code'] = embed_code
      l.save!
    end
  end

  it 'should call sync_one!' do
    expect_any_instance_of(ContactList).to receive(:sync_one!).with("test.testerson@example.com", "Test Testerson")
    perform!
  end

  it 'should update last_synced_at' do
    expect { perform! }.to change { contact_list.last_synced_at }.from(NilClass).to(Time)
  end

  private

  def perform!
    subject.invoke(contact_list.id, user[:email], user[:name])
    contact_list.reload
  end
end
