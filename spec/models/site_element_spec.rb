require 'spec_helper'

describe SiteElement do
  fixtures :all

  it "belongs to a site through a rule set" do
    bar = site_elements(:zombo_traffic)
    bar.site.should == sites(:zombo)

    bar.rule = nil
    bar.site.should be_nil
  end
end
