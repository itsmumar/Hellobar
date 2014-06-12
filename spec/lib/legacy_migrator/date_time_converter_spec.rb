require 'spec_helper'

describe LegacyMigrator::DateTimeConverter do
  class SexyTime
    extend LegacyMigrator::DateTimeConverter
  end

  context '#convert_start_time' do
    it 'returns nil if start time is blank' do
      SexyTime.convert_start_time('', '').should be_blank
    end

    it 'converts start time properly' do
      date_string = "2014-12-25"
      timezone = "(GMT-05:00) Eastern Time (US & Canada)"

      expected_time_string = "2014-12-25T00:00:00-05:00"

      SexyTime.convert_start_time(date_string, timezone).to_s.should == expected_time_string
    end

    it 'handles crazy other timezones just in case' do
      date_string = "2014-12-25"
      timezone = "(GMT-11:00) American Samoa"

      expected_time_string = "2014-12-25T00:00:00-11:00"

      SexyTime.convert_start_time(date_string, timezone).to_s.should == expected_time_string
    end

    it 'handles visitor as a UTC timezone' do
      date_string = "2014-12-25"
      timezone = "visitor"

      expected_time_string = "2014-12-25T00:00:00+00:00"

      SexyTime.convert_start_time(date_string, timezone).to_s.should == expected_time_string
    end
  end

  context '#convert_end_time' do
    it 'returns nil if end time is blank' do
      SexyTime.convert_end_time('', '').should be_blank
    end

    it 'converts end time properly' do
      date_string = "2014-12-25"
      timezone = "(GMT-05:00) Eastern Time (US & Canada)"

      expected_time_string = "2014-12-25T23:59:59-05:00"

      SexyTime.convert_end_time(date_string, timezone).to_s.should == expected_time_string
    end

    it 'handles crazy other timezones just in case' do
      date_string = "2014-12-25"
      timezone = "(GMT-11:00) American Samoa"

      expected_time_string = "2014-12-25T23:59:59-11:00"

      SexyTime.convert_end_time(date_string, timezone).to_s.should == expected_time_string
    end

    it 'handles visitor as a UTC timezone' do
      date_string = "2014-12-25"
      timezone = "visitor"

      expected_time_string = "2014-12-25T23:59:59+00:00"

      SexyTime.convert_end_time(date_string, timezone).to_s.should == expected_time_string
    end
  end
end
