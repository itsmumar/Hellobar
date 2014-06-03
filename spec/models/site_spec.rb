require 'spec_helper'

describe Site do
  fixtures :all

  it "is able to access its owner" do
    sites(:zombo).owner.should == users(:joey)
  end
end
