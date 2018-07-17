feature 'Collect Email goal', :js do
  let(:user) { create :user }
  let(:site) { create :site, :with_rule, user: user }

  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:ab_variation).and_return('variant')

    create :contact_list, site: site

    sign_in user

    visit new_site_site_element_path(site)

    find('.goal-block.contacts').click_on('Select This Goal')
    click_button 'Continue'

    find('.step-links__item', text: 'Goals').click

    @phone_field = find('.item-block[data-field-type="builtin-phone"]')
    @phone_field.find('.hellobar-icon-check-mark').click if @phone_field[:class].include?('is-selected')

    @name_field = find('.item-block[data-field-type="builtin-name"]')
    @name_field.find('.hellobar-icon-check-mark').click if @name_field[:class].include?('is-selected')
  end

  scenario 'only built-in-email enabled' do
    find('a', text: 'Save & Publish').click
    expect(page).to have_content('Summary')
    se = SiteElement.last
    se_settings = se.settings['fields_to_collect'].map { |a| [a['type'], a['is_enabled']] }.to_h
    expect(se_settings['builtin-phone']).to eq(false)
  end

  scenario 'built-in-phone enabled' do
    @phone_field.hover
    @phone_field.find('.hellobar-icon-check-mark').click
    find('a', text: 'Save & Publish').click
    expect(page).to have_content('Summary')
    se = SiteElement.last
    se_settings = se.settings['fields_to_collect'].map { |a| [a['type'], a['is_enabled']] }.to_h
    expect(se_settings['builtin-phone']).to eq(true)
  end

  scenario 'built-in-name enabled' do
    @name_field.hover
    @name_field.find('.hellobar-icon-check-mark').click
    find('a', text: 'Save & Publish').click
    expect(page).to have_content('Summary')
    se = SiteElement.last
    se_settings = se.settings['fields_to_collect'].map { |a| [a['type'], a['is_enabled']] }.to_h
    expect(se_settings['builtin-name']).to eq(true)
  end

  scenario 'only multiple built-in fields enabled' do
    @name_field.hover
    @name_field.find('.hellobar-icon-check-mark').click
    @phone_field.hover
    @phone_field.find('.hellobar-icon-check-mark').click
    find('a', text: 'Save & Publish').click
    expect(page).to have_content('Summary')
    se = SiteElement.last
    se_settings = se.settings['fields_to_collect'].map { |a| [a['type'], a['is_enabled']] }.to_h
    expect(se_settings['builtin-phone']).to eq(true)
    expect(se_settings['builtin-name']).to eq(true)
    expect(se_settings['builtin-email']).to eq(true)
  end

  scenario 'custom field' do
    find('.step-links__item .caption', text: 'Type').click
    find('a.change-selection').click
    find('h6', text: 'Modal').click
    find('span', text: 'Autodetect colors from site').click
    find('.step-links__item .caption', text: 'Goals').click
    find('div.item-block.add', text: 'Add field').click

    expect(page).to have_selector '.new-item-prototype > input'
    find('.new-item-prototype > input').set "Age\n"

    find('a', text: 'Save & Publish').click
    expect(page).to have_content('Summary')

    find('a', text: 'Manage').click
    find('.dropdown-wrapper.adjusted').hover
    find('.dropdown-wrapper.adjusted').find('a', text: 'Edit').click

    expect(page).to have_content('Age')
    expect(page).to have_css('.item-block[data-field-type="text"] .hellobar-icon-check-mark')
    expect(page).to have_content('Add field')
  end
end
