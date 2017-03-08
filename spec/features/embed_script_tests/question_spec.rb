require 'integration_helper'

feature 'Site with a question modal', :js do
  before do
    @element = create(:modal_element,
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

    allow_any_instance_of(ScriptGenerator).to receive(:pro_secret).and_return('random')
    @path = generate_file_and_return_path(@element.site.id)
  end

  scenario 'displays the question modal' do
    visit site_path_to_url(@path)

    # force capybara to wait until iframe is loaded
    page.has_xpath?('.//iframe[@id="random-container"]')

    page.driver.browser.frame_focus('random-container-0')

    expect(page).to have_content(@element.question)
  end
end
