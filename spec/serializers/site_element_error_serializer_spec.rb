require 'spec_helper'

describe SiteElementErrorSerializer do
  fixtures :all

  let(:element) { site_elements(:zombo_traffic) }

  it "should translate missing element subtype error into something more readable" do
    element.element_subtype = nil
    element.valid?

    serializer = SiteElementErrorSerializer.new(element)
    serializer.as_json[:full_messages].should == ["You must select a type in the \"settings\" section"]
  end
end
