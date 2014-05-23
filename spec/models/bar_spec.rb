require 'spec_helper'

describe Bar, '#settings' do
  let(:bar) { Bar.new }

  it 'returns the associated bar setting if present' do
    setting = BarSetting.new
    bar.bar_setting = setting

    bar.settings.should == setting
  end

  it 'returns a new BarSetting instance if not present' do
    new_instance = double 'bar setting'
    BarSetting.should_receive(:new).and_return(new_instance)

    bar.settings.should == new_instance
  end
end
