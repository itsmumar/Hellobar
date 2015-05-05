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
end
