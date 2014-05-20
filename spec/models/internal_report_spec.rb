require 'spec_helper'

describe InternalReport do
  before do
    InternalReport.clear
  end

  it "should return nil for a report not yet set" do
    InternalReport.get_data("test").should == nil
  end

  it "should let you return a report that is set" do
    data = {"foo"=>"bar"}
    InternalReport.set("test", data)
    InternalReport.get_data("test").should == data
  end

  it "should let you update an existing report" do
    data = {"foo"=>"bar"}
    InternalReport.set("test", data)
    InternalReport.get_data("test").should == data
    data = {"foo"=>"bar2"}
    InternalReport.set("test", data)
    InternalReport.get_data("test").should == data
  end

  it "should not error out when you generate the reports" do
    InternalReport.generate_all
  end
end
