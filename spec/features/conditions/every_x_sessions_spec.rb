require 'integration_helper'

feature 'Every x number of sessions condition', js: true do
  def set_ns_cookie(page, sessions)
    page.execute_script("
      var d = new Date();
      HB.setVisitorData('lv', (d.getTime())/1000);
      HB.setVisitorData('ns', #{ sessions });
    ")
  end

  before(:each) do
    @element = create(:site_element)
    allow_any_instance_of(ScriptGenerator).to receive(:pro_secret).and_return('random')

    @test_doesnt_exist = proc do |day|
      visit site_path_to_url(@path).to_s
      set_ns_cookie(page, day)
      visit site_path_to_url(@path).to_s # Reload the page
      sleep(1) # Give time for JS to execute
      expect(page).to_not have_xpath('.//iframe[@id="random-container"]')
    end

    @test_does_exist = proc do |day|
      visit site_path_to_url(@path).to_s
      set_ns_cookie(page, day)
      visit site_path_to_url(@path).to_s

      # force capybara to wait until iframe is loaded
      page.has_xpath?('.//iframe[@id="random-container"]')
      within_frame 'random-container-0' do
        expect(page).to have_content(@element.headline)
      end
    end
  end

  context 'condition is every 4 sessions' do
    before(:each) do
      @element.rule.conditions << create(:condition, operand: 'every', segment: 'EveryXSession', value: '4')
      @path = generate_file_and_return_path(@element.site.id)
    end

    it 'shows if the number of sessions is divisible by 4' do
      @test_does_exist.call(0)
      @test_does_exist.call(4)
      @test_does_exist.call(8)
    end

    it "doesn't show if number of sessions is not divisible by 4" do
      @test_doesnt_exist.call(1)
      @test_doesnt_exist.call(2)
      @test_doesnt_exist.call(3)
    end
  end
end
