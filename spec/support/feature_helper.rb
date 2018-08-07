SimpleCov.command_name 'test:features' if ENV['COVERAGE'] || ENV['CI']

module FeatureHelper
  def sign_in(user)
    login_as user, scope: :user, run_callbacks: false

    visit '/'
  end

  def wait_for_ajax
    Timeout.timeout(2) do
      loop until finished_all_ajax_requests?
    end
  end

  def finished_all_ajax_requests?
    page.evaluate_script('jQuery.active')&.zero?
  end

  def bypass_setup_steps(count)
    count.times { scroll_and_click('Next', 'step-wrapper') }
  end

  def submit_form
    find('input[name="commit"]').click
  end

  def go_to_tab(name)
    find('.step-links__item .caption', text: name).click
  end

  private

  def scroll_and_click(link_label, scroll_class)
    page.execute_script("var step = $('.#{ scroll_class }'); step.scrollTop(step.height())")
    page.find('a', text: link_label).click
  end
end
