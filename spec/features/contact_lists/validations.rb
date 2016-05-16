require 'integration_helper'

feature "Contact list modal", js: true do
  let!(:site) { create(:site, :with_rule) }
  before { @user = login }
  after { devise_reset }

  context "has been opened" do
    before do
      site.site_memberships.create(user_id: @user.id, role: "owner")
      bar = create(:site_element)
      bar.update_attributes(rule_id: site.rules.first.id)
      site.contact_lists.create(name: "My List")
      Hello::DataAPI.stub(contact_list_totals: {})
      visit "/sites/#{site.id}/contact_lists"
      find("#new-contact-list").click
    end

    it "should show the correct copy" do
      expect(page.html).to have_content "Where do you want your contacts stored?"
    end

    it "should update with correct provider instructions" do
      select "GetResponse", from: "contact_list_provider"
      expect(page).to have_content "Your API key from GetResponse"
    end

    it "should not submit form with api key blank" do
      select "GetResponse", from: "contact_list_provider"
      fill_in 'contact_list_api_key', with: ''
      find(".provider-instructions-block a.button").click
      expect(page).to have_content "Your API key from GetResponse"
    end

    it "should connect account" do
      select "GetResponse", from: "contact_list_provider"
      fill_in 'contact_list_api_key', with: 'myapikey'
      find(".provider-instructions-block a.button").click
      expect(page).to have_content "Disconnect GetResponse"
    end
  end
end