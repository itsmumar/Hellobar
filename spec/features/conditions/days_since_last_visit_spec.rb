require 'integration_helper'

feature 'Days since last visit condition', js: true do
  def set_lv_cookie(page, days)
    page.execute_script("
      var d = new Date();
      d.setDate(d.getDate() - (#{ days }));
      hellobar('visitor').inspect().setData('lv', (d.getTime())/1000);
    ")
  end

  let(:element) { create(:site_element) }

  def visit_and_set_cookie(day)
    visit test_site_path(id: element.site.id)
    set_lv_cookie(page, day)
    visit test_site_path(id: element.site.id) # Reload the page
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

  context 'condition is days since last visit < 5' do
    before(:each) do
      element.rule.conditions << create(:condition, operand: 'less_than', segment: 'LastVisitCondition', value: '5')
    end

    it 'does not shows if last visit was greater than 5 days ago' do
      visit_and_set_cookie(6)
      @test_doesnt_exist.call
    end

    it 'shows if last visit was less than 5 days ago' do
      visit_and_set_cookie(4)
      @test_does_exist.call
    end
  end

  context 'condition is days since last visit > 5' do
    before(:each) do
      element.rule.conditions << create(:condition, operand: 'greater_than', segment: 'LastVisitCondition', value: '5')
    end

    it 'does not shows if last visit was less than 5 days ago' do
      visit_and_set_cookie(4)
      @test_doesnt_exist.call
    end

    it 'shows if last visit was greater than 5 days ago' do
      visit_and_set_cookie(6)
      @test_does_exist.call
    end
  end

  context 'condition is days since last visit = 5' do
    before(:each) do
      element.rule.conditions << create(:condition, operand: 'is', segment: 'LastVisitCondition', value: '5')
    end

    it 'does not shows if last visit was not 5 days ago' do
      visit_and_set_cookie(4)
      @test_doesnt_exist.call
    end

    it 'shows if last visit was 5 days ago' do
      visit_and_set_cookie(5)
      @test_does_exist.call
    end
  end

  context 'condition is days since last visit between 5 and 7 days ago' do
    before(:each) do
      element.rule.conditions << create(:condition, operand: 'between', segment: 'LastVisitCondition', value: ['5', '7'])
    end

    it 'does not shows if last visit was not between 5 and 7 days ago' do
      visit_and_set_cookie(4)
      @test_doesnt_exist.call
    end

    it 'shows if last visit was 6 days ago' do
      visit_and_set_cookie(6)
      @test_does_exist.call
    end
  end
end
