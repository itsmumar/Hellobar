require 'spec_helper'

describe ContactLists::Destroy do
  def destroy(action:)
    action = ContactLists::SITE_ELEMENTS_ACTIONS[action] if action.is_a?(Symbol)
    ContactLists::Destroy.run(
      contact_list: contact_list,
      site_elements_action: action
    )
  end

  let(:contact_list) { create(:contact_list) }
  let(:site_element) { create(:site_element) }

  before :each do
    contact_list.site_elements << site_element
  end

  context 'when list has no site elements' do
    it 'destroys the contact list' do
      contact_list.site_elements = []

      expect {
        destroy(action: :delete)
      }.to change { ContactList.count }.by(-1)
    end
  end

  context 'when user does not specify a valid site action' do
    it 'returns false' do
      expect(destroy(action: -1)).to be_false
    end

    it 'has an error' do
      destroy(action: -1)

      expect(contact_list.errors[:base]).to include(
        'Must specify an action for existing bars, modals, sliders, and takeovers'
      )
    end
  end

  context 'when user specifies keeping elements' do
    it 'destroys the contact list' do
      destroy(action: :keep)

      expect(ContactList.where(id: contact_list.id)).to be_empty
    end

    it 'creates a new list' do
      contact_list_ids = ContactList.all.pluck(:id)
      destroy(action: :keep)

      last_id = ContactList.last.id
      expect(contact_list_ids).to_not include(last_id)
    end

    it 'keeps the site elements' do
      expect {
        destroy(action: :keep)
      }.not_to change { SiteElement.where('deleted_at is not null').count }
    end

    it 'sets all site elements to new list' do
      destroy(action: :keep)

      expect(site_element.reload.contact_list_id).not_to eq(contact_list.id)
    end
  end

  context 'when action is a string' do
    it 'destroys current contact list and creates a new one' do
      expect {
        destroy(action: ContactLists::SITE_ELEMENTS_ACTIONS[:keep].to_s)
      }.not_to change { ContactList.count }
    end
  end

  context 'when user specifies deleting elements' do
    it 'destroys the contact list' do
      expect {
        destroy(action: :delete)
      }.to change { ContactList.count }.by(-1)
    end

    it 'destroys all the site elements' do
      expect {
        destroy(action: :delete)
      }.to change { SiteElement.deleted.count }.by(1)
    end
  end
end
