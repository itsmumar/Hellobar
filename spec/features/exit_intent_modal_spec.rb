require 'integration_helper'

feature "Exit intent modal interaction", js: true do
  before do
    allow(ModalHelper).to receive(:allow_exit_intent_modal?).and_return(true)
    allow_any_instance_of(ApplicationHelper).to receive(:get_ab_variation).with("Exit Intent Pop-up Based on Bar Goals 2016-06-08").and_return('pop_up')
    @user = login
  end

  after { devise_reset }

  scenario "user sees announcement popup" do
    allow_any_instance_of(ModalHelper).to receive(:most_viewed_site_element_subtype).with(@user).and_return("announcement")
    # move mouse out of screen here?
    expect(page).to have_content("Double your announcement impact!")
  end
end
