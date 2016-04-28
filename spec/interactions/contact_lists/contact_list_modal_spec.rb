require 'spec_helper'
require 'integration_helper'

# describe "Connecting a contact list via modal" do
#   fixtures :all
#
#   let!(:site) { create(:site, :with_rule) }
#   before { @user = login }
#   after { devise_reset }
#
#   it "should open when 'New Contact List' is clicked" do
#     site.site_memberships.create(user_id: @user.id, role: "owner")
#     bar = site_elements(:zombo_traffic)
#     rule = site.rules.first
#     bar.rule = rule
#     bar.save
#     site.contact_lists.create(name: "My List")
#     Hello::DataAPI.stub(contact_list_totals: {})
#     visit "/sites/#{site.id}/contact_lists"
#     find("#new-contact-list").click
#     puts page.body
#     sleep 2
#     expect(page).to have_content "Where do you want your contacts stored?"
#   end
#
# end
