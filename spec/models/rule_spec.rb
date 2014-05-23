require 'spec_helper'

describe Rule, '#settings' do
  let(:rule) { Rule.new }

  it 'returns the associated rule setting if present' do
    setting = RuleSetting.new
    rule.rule_setting = setting

    rule.settings.should == setting
  end

  it 'returns a new RuleSetting instance if not present' do
    new_instance = double 'rule setting'
    RuleSetting.should_receive(:new).and_return(new_instance)

    rule.settings.should == new_instance
  end
end
