require "spec_helper"

describe DigestMailer do
  fixtures :all

  describe 'weekly_digest' do
    let(:site) { sites(:zombo) }
    let(:user) { site.owner }
    let(:mail) { DigestMailer.weekly_digest(site) }

    it 'should work correctly when there are no site elements' do
      site.site_elements.each(&:destroy)
      Hello::DataAPI.stub(lifetime_totals: {})
      expect{mail.body}.to_not raise_error
    end

    it 'should display n/a if history is too short' do
      data = {}.tap do |d|
        site.site_elements.each { |se| d[se.id.to_s] = Hello::DataAPI::Performance.new([[0, 1]])}
      end
      Hello::DataAPI.stub(:lifetime_totals).and_return(data)
      Hello::DataAPI.stub(:lifetime_totals_by_type).and_return({:total=>Hello::DataAPI::Performance.new([[0, 1]])})
      expect(mail.body.encoded).to match("n/a")
    end

    it 'should not raise a divide by zero error when there are 0 conversions' do
      data = {}.tap do |d|
        site.site_elements.each { |se| d[se.id.to_s] = Hello::DataAPI::Performance.new([[0, 0]] * 365)}
      end
      Hello::DataAPI.stub(:lifetime_totals).and_return(data)
      Hello::DataAPI.stub(:lifetime_totals_by_type).and_return({:total=>Hello::DataAPI::Performance.new([[0, 0]] * 365)})
      expect{mail.body}.to_not raise_error
      expect(mail.body.encoded).to match("0%")
    end

    it 'should show total -10% week to week conversion' do
      dt = [[0,0], [0, 0], [10, 1], [10, 1], [10, 1], [10, 1], [10, 1], [10, 1], [10, 1], [20, 1]]
      data = {}.tap do |d|
        site.site_elements.each { |se| d[se.id.to_s] = Hello::DataAPI::Performance.new(dt)}
      end
      Hello::DataAPI.stub(:lifetime_totals).and_return(data)
      Hello::DataAPI.stub(:lifetime_totals_by_type).and_return({:total=>Hello::DataAPI::Performance.new(dt)})
      expect{mail.body}.to_not raise_error
      expect(mail.body.encoded).to match("-10%")
    end

    it 'should show total +100% week to week conversions' do
      dt = [[0,0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [20, 20]]
      data = {}.tap do |d|
        site.site_elements.each { |se| d[se.id.to_s] = Hello::DataAPI::Performance.new(dt)}
      end
      Hello::DataAPI.stub(:lifetime_totals).and_return(data)
      Hello::DataAPI.stub(:lifetime_totals_by_type).and_return({:total=>Hello::DataAPI::Performance.new(dt)})
      expect{mail.body}.to_not raise_error
      expect(mail.body.encoded).to match("\\+100%")
    end
  end
end
