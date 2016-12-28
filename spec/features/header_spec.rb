require 'integration_helper'

feature "Header Navigation", js: true do
  before { login }

  xscenario "can expose site nav via click" do
    find('.header-nav-wrapper').click
    expect(page).to have_content('Site Settings')
  end

  xscenario "can dismiss site nav via click of element" do
    find('.header-nav-wrapper').click
    find('.header-nav-wrapper').click
    expect(page).to_not have_content('Site Settings')
  end

  xscenario "can dismiss site nav via click outside element" do
    find('.header-nav-wrapper').click
    find('.installation-page').click
    expect(page).to_not have_content('Site Settings')
  end

  xscenario "does not reveal on :hover due to .no-hover" do
    find('.header-nav-wrapper').hover
    expect(page).to_not have_content('Site Settings')
  end

  xscenario "reveals on :hover if .no-hover is missing" do
    page.execute_script("$('.header-nav-wrapper .dropdown-wrapper').removeClass('no-hover')")
    find('.header-nav-wrapper').hover
    expect(page).to have_content('Site Settings')
  end

  xscenario "can expose site nav via click if .no-hover is missing" do
    page.execute_script("$('.header-nav-wrapper .dropdown-wrapper').removeClass('no-hover')")
    find('.header-nav-wrapper').click
    expect(page).to have_content('Site Settings')
  end
end
