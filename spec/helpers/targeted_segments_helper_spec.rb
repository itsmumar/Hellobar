require 'spec_helper'

describe TargetedSegmentsHelper do
  fixtures :all

  describe 'segment_description' do
    it 'correctly expands short segment strings into humanized descriptions' do
      segment_description('co:USA').should == 'Country is USA'
      segment_description('dv:Mobile').should == 'Device is Mobile'
    end

    it 'correctly expands short segment strings when value contains a colin' do
      segment_description('rf:http://zombo.com').should == 'Referrer URL is http://zombo.com'
    end
  end

  describe 'create_targeted_content_link' do
    it 'uses an existing rule if one already matches' do
      link = create_targeted_content_link(sites(:zombo), 'dv:mobile')
      link.should =~ /rule_id=#{rules(:zombo_mobile).id}/
    end

    it 'links to targeted segments controller if no matching rule exists' do
      link = create_targeted_content_link(sites(:zombo), 'dv:desktop')
      link.should =~ /targeted_segments/
      link.should =~ /dv%3Adesktop/
    end
  end

  describe 'rule_for_segment_and_value' do
    it "returns a rule if it has a single condition of 'segment is value'" do
      rule = rule_for_segment_and_value(sites(:zombo), 'dv', 'mobile')
      rule.should == rules(:zombo_mobile)
    end
  end
end
