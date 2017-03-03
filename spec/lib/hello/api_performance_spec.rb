require 'spec_helper'

describe Hello::DataAPI::Performance do
  describe '#views' do
    it 'should return total views' do
      Hello::DataAPI::Performance.new([[10, 5], [12, 6]]).views.should == 12
    end

    it 'should return 0 if no data' do
      Hello::DataAPI::Performance.new([]).views.should == 0
    end
  end

  describe '#conversions' do
    it 'should return total conversions' do
      Hello::DataAPI::Performance.new([[10, 5], [12, 6]]).conversions.should == 6
    end

    it 'should return 0 if no data' do
      Hello::DataAPI::Performance.new([]).conversions.should == 0
    end
  end

  describe '#views_between' do
    it 'should compute views between two dates' do
      d = Hello::DataAPI::Performance.new([[0, 0], [10, 5], [20, 10], [30, 15], [35, 20]])
      d.views_between(Date.today - 3, Date.today).should == 25
    end

    it 'should calculate from 0 if you ask for data for a date too far in the past' do
      d = Hello::DataAPI::Performance.new([[10, 5], [20, 10], [30, 15], [35, 20]])
      d.views_between(Date.today - 10, Date.today).should == 35
    end

    it 'should calculate from the latest if you ask for data for a date too far in the future' do
      d = Hello::DataAPI::Performance.new([[10, 5], [20, 10], [30, 15], [35, 20]])
      d.views_between(Date.today - 2, Date.today+10).should == 15
    end
  end

  describe '#conversions_between' do
    it 'should compute conversions between two dates' do
      d = Hello::DataAPI::Performance.new([[0, 0], [10, 5], [20, 10], [30, 15], [35, 20]])
      d.conversions_between(Date.today - 3, Date.today).should == 15
    end

    it 'should calculate from 0 if not enough data' do
      d = Hello::DataAPI::Performance.new([[10, 5], [20, 10], [30, 15], [35, 20]])
      d.conversions_between(Date.today - 10, Date.today).should == 20
    end
  end

  describe '#conversion_percent_between' do
    it 'should compute conversions between two dates' do
      d = Hello::DataAPI::Performance.new([[0, 0], [10, 5], [20, 10], [30, 15], [35, 20]])
      d.conversion_percent_between(Date.today - 3, Date.today).should == 15 / 25.0
    end

    it 'should calculate the total if not enough data' do
      d = Hello::DataAPI::Performance.new([[10, 5], [20, 10], [30, 15], [35, 20]])
      d.conversion_percent_between(Date.today - 10, Date.today).should == 20.0 / 35.0
    end
  end
end
