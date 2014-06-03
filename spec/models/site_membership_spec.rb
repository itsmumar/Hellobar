require 'spec_helper'

describe SiteMembership do
  fixtures :all

  it "can only have one owner per site" do
    membership = SiteMembership.new(:site => sites(:zombo), :user => users(:wootie), :role => "editor")
    membership.should be_valid

    membership.role = "owner"
    membership.should_not be_valid
  end
end
