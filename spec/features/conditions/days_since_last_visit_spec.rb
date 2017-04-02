require 'integration_helper'

feature 'Days since last visit condition', js: true do
  def set_lv_cookie(page, days)
    page.execute_script("
      var d = new Date();
      d.setDate(d.getDate() - (#{ days }));
      hellobar('visitor').introspect().setData('lv', (d.getTime())/1000);
    ")
  end

  before(:each) do
    @element = create(:site_element)
    allow_any_instance_of(ScriptGenerator).to receive(:pro_secret).and_return('random')

    @test_doesnt_exist = proc do |day|
      visit site_path_to_url(@path)
      set_lv_cookie(page, day)
      visit site_path_to_url(@path) # Reload the page
      sleep(1) # Give time for JS to execute
      expect(page).to_not have_xpath('.//iframe[@id="random-container"]')
    end

    @test_does_exist = proc do |day|
      visit site_path_to_url(@path)
      set_lv_cookie(page, day)
      visit site_path_to_url(@path)

      # force capybara to wait until iframe is loaded
      page.has_xpath?('.//iframe[@id="random-container"]')
      within_frame 'random-container-0' do
        expect(page).to have_content(@element.headline)
      end
    end
  end

  context 'condition is days since last visit < 5' do
    before(:each) do
      @element.rule.conditions << create(:condition, operand: 'less_than', segment: 'LastVisitCondition', value: '5')
      @path = generate_file_and_return_path(@element.site.id)
    end

    it 'does not shows if last visit was greater than 5 days ago' do
      @test_doesnt_exist.call(6)
    end

    it 'shows if last visit was less than 5 days ago' do
      @test_does_exist.call(4)
    end
  end

  context 'condition is days since last visit > 5' do
    before(:each) do
      @element.rule.conditions << create(:condition, operand: 'greater_than', segment: 'LastVisitCondition', value: '5')
      @path = generate_file_and_return_path(@element.site.id)
    end

    it 'does not shows if last visit was less than 5 days ago' do
      @test_doesnt_exist.call(4)
    end

    it 'shows if last visit was greater than 5 days ago' do
      @test_does_exist.call(6)
    end
  end

  context 'condition is days since last visit = 5' do
    before(:each) do
      @element.rule.conditions << create(:condition, operand: 'is', segment: 'LastVisitCondition', value: '5')
      @path = generate_file_and_return_path(@element.site.id)
    end

    it 'does not shows if last visit was not 5 days ago' do
      @test_doesnt_exist.call(4)
    end

    it 'shows if last visit was 5 days ago' do
      @test_does_exist.call(5)
    end
  end

  context 'condition is days since last visit between 5 and 7 days ago' do
    before(:each) do
      @element.rule.conditions << create(:condition, operand: 'between', segment: 'LastVisitCondition', value: ['5', '7'])
      @path = generate_file_and_return_path(@element.site.id)
    end

    it 'does not shows if last visit was not between 5 and 7 days ago' do
      @test_doesnt_exist.call(4)
    end

    it 'shows if last visit was 6 days ago' do
      @test_does_exist.call(6)
    end
  end
end
