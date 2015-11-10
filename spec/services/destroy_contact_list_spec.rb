require 'spec_helper'

describe DestroyContactList do
  fixtures :all

  describe "#destroy" do
    let(:contact_list) { contact_lists(:zombo_contacts) }

    context "when list has no site elements" do
      it "destroys the contact list" do
        destroyer = DestroyContactList.new(contact_list)

        expect {
          destroyer.destroy(DestroyContactList::SITE_ELEMENTS_ACTIONS[:delete])
        }.to change { ContactList.count }.by(-1)
      end
    end

    context "when list has site elements" do
      let(:site_element) { site_elements(:zombo_email) }

      before do
        contact_list.site_elements << site_element
      end

      context "when user does not specify a valid site action" do
        let(:invalid_action) { 3 }

        it "returns false" do
          destroyer = DestroyContactList.new(contact_list)

          result = destroyer.destroy(invalid_action)

          expect(result).to be_false
        end

        it "has an error" do
          destroyer = DestroyContactList.new(contact_list)

          destroyer.destroy(invalid_action)

          expect(destroyer.errors[:base]).to include(I18n.t(
            "services.destroy_contact_list.invalid_site_elements_action"
          ))
        end
      end

      context "when user specifies keeping elements" do
        it "destroys the contact list" do
          destroyer = DestroyContactList.new(contact_list)

          destroyer.destroy(DestroyContactList::SITE_ELEMENTS_ACTIONS[:keep])

          expect(ContactList.where(id: contact_list.id)).to be_empty
        end

        it "creates a new list" do
          contact_list_ids = ContactList.all.pluck(:id)
          destroyer = DestroyContactList.new(contact_list)

          destroyer.destroy(DestroyContactList::SITE_ELEMENTS_ACTIONS[:keep])

          last_id = ContactList.last.id
          expect(contact_list_ids).to_not include(last_id)
        end

        it "sets all site elements to new list" do
          destroyer = DestroyContactList.new(contact_list)

          destroyer.destroy(DestroyContactList::SITE_ELEMENTS_ACTIONS[:keep])

          expect(site_element.reload.contact_list_id).not_to eq(contact_list.id)
        end

        context "when action is a string" do
          it "destroys current contact list and creates a new one" do
            destroyer = DestroyContactList.new(contact_list)

            expect {
              destroyer.destroy(DestroyContactList::SITE_ELEMENTS_ACTIONS[:keep].to_s)
            }.not_to change { ContactList.count }
          end
        end
      end

      context "when user specifies deleting elements" do
        it "destroys the contact list" do
          destroyer = DestroyContactList.new(contact_list)

          expect {
            destroyer.destroy(DestroyContactList::SITE_ELEMENTS_ACTIONS[:delete])
          }.to change { ContactList.count }.by(-1)
        end

        it "destroys all the site elements" do
          destroyer = DestroyContactList.new(contact_list)

          expect {
            destroyer.destroy(DestroyContactList::SITE_ELEMENTS_ACTIONS[:delete])
          }.to change { SiteElement.count }.by(-1)
        end
      end
    end
  end
end
