require 'spec_helper'

describe Bar do
  fixtures :all

  it "belongs to a site through a rule set" do
    bar = bars(:zombo_traffic)
    bar.site.should == sites(:zombo)

    bar.rule = nil
    bar.site.should be_nil
  end
end
