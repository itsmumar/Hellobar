require 'spec_helper'

describe SiteElementSerializer do
  let(:element) { create(:site_element, :traffic) }

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

  it 'serializes :email_redirect' do
    site_element = build_stubbed :site_element, :email_with_redirect

    serialized_site_element = SiteElementSerializer.new site_element

    expect(serialized_site_element.serializable_hash).to have_key :email_redirect
  end
end
