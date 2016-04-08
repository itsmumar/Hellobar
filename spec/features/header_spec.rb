require 'integration_helper'

feature "Header Navigation", js: true do
  after { devise_reset }

  scenario "can expose site nav via click" do
    login
    find('.header-nav-wrapper').click
    expect(page).to have_content('Site Settings')
  end

  scenario "can dismiss site nav via click of element" do
    login
    find('.header-nav-wrapper').click
    find('.header-nav-wrapper').click
    expect(page).to_not have_content('Site Settings')
  end

  scenario "can dismiss site nav via click outside element" do
    login
    find('.header-nav-wrapper').click
    find('.installation-page').click
    expect(page).to_not have_content('Site Settings')
  end

  scenario "does not reveal on :hover due to .no-hover" do
    login
    find('.header-nav-wrapper').hover
    expect(page).to_not have_content('Site Settings')
  end

  scenario "reveals on :hover if .no-hover is missing" do
    login
    page.execute_script("$('.header-nav-wrapper .dropdown-wrapper').removeClass('no-hover')")
    find('.header-nav-wrapper').hover
    expect(page).to have_content('Site Settings')
  end
end
