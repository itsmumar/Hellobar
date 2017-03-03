require 'spec_helper'

describe SiteElementSerializer do
  fixtures :all

  let(:element) { site_elements(:zombo_traffic) }

  it 'should translate missing element subtype error into something more readable' do
    element.element_subtype = nil
    element.valid?

    serializer = SiteElementSerializer.new(element)
    serializer.as_json[:full_error_messages].should == ['You must select your goal in the "goals" section']
  end

  it 'passes the scope to the site serializer' do
    user = create(:user)
    serializer = SiteElementSerializer.new(element, scope: user)
    expect(SiteSerializer).to receive(:new).with(element.site, scope: user)
    serializer.as_json
  end
end
