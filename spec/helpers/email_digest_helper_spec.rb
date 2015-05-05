require 'spec_helper'

describe EmailDigestHelper, type: :helper do
  context "format_number" do
    it "should format 1,580 as 1.6k" do
      helper.format_number(1_580).should == "1.6k"
    end

    it "should format 12,800 as 13k" do
      helper.format_number(12_800).should == "13k"
    end

    it "should format 874 as 874" do
      helper.format_number(874).should == "874"
    end

    it "should format 112,500 as 112k" do
      helper.format_number(112_300).should == "112k"
    end
  end

  context "formatted_percent" do
    it "should format 0.53" do
      helper.formatted_percent(0.53).should == "+0.53%"
    end

    it "should format 1.64" do
      helper.formatted_percent(1.64).should == "+1.6%"
    end

    it "should format 11.78" do
      helper.formatted_percent(11.78).should == "+12%"
    end

    it "should format 118.3" do
      helper.formatted_percent(118.3).should == "+118%"
    end

    it "should format -89.3" do
      helper.formatted_percent(-89.3).should == "-89%"
    end
  end
end
