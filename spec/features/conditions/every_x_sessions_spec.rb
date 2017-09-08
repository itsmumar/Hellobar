require 'integration_helper'

feature 'Every x number of sessions condition', js: true do
  let(:element) { create(:site_element) }

  def set_ns_cookie(page, sessions)
    page.execute_script("
      var d = new Date();
      hellobar('visitor').inspect().setData('lv', (d.getTime())/1000);
      hellobar('visitor').inspect().setData('ns', #{ sessions });
    ")
  end

  def visit_and_set_cookie(day)
    visit test_site_path(element.site.id)
    set_ns_cookie(page, day)
    visit test_site_path(element.site.id) # Reload the page
  end

  before(:each) do
    @test_doesnt_exist = proc do
      sleep(1) # Give time for JS to execute
      expect(page).not_to have_xpath('.//iframe[@id="random-container"]')
    end

    @test_does_exist = proc do
      # force capybara to wait until iframe is loaded
      page.has_xpath?('.//iframe[@id="random-container"]')
      within_frame 'random-container-0' do
        expect(page).to have_content(element.headline)
      end
    end
  end

  context 'condition is every 4 sessions' do
    before(:each) do
      element.rule.conditions << create(:condition, operand: 'every', segment: 'EveryXSession', value: '4')
    end

    it 'shows if the number of sessions is divisible by 4' do
      visit_and_set_cookie(0)
      @test_does_exist.call

      visit_and_set_cookie(4)
      @test_does_exist.call

      visit_and_set_cookie(8)
      @test_does_exist.call
    end

    it "doesn't show if number of sessions is not divisible by 4" do
      visit_and_set_cookie(1)
      @test_doesnt_exist.call

      visit_and_set_cookie(5)
      @test_doesnt_exist.call

      visit_and_set_cookie(7)
      @test_doesnt_exist.call
    end
  end
end
