require 'integration_helper'

feature 'Site with a question modal', :js do
  let(:element) do
    create(:modal,
      use_question: true,
      question: 'What is 1+1?',
      answer1: 'its 2',
      answer2: 'its 3',
      answer1response: 'Correct!',
      answer1caption: 'Correct Caption!',
      answer1link_text: 'Great!',
      answer2response: 'Incorrect!',
      answer2caption: 'Incorrect Caption!',
      answer2link_text: 'Boo!')
  end

  scenario 'displays the question modal' do
    visit test_site_path(id: element.site.id)

    # force capybara to wait until iframe is loaded
    page.has_xpath?('.//iframe[@id="random-container"]')

    within_frame('random-container-0') do
      expect(page).to have_content(element.question)
    end
  end
end
