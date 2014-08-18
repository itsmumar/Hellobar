require 'spec_helper'

describe SiteElement do
  fixtures :all

  it "belongs to a site through a rule set" do
    bar = site_elements(:zombo_traffic)
    bar.site.should == sites(:zombo)

    bar.rule = nil
    bar.site.should be_nil
  end

  it "requires a contact list if element_subtype is \"email\"" do
    element = site_elements(:zombo_traffic)
    element.should be_valid

    element.element_subtype = "email"
    element.should_not be_valid
    element.errors[:contact_list].should == ["can't be blank"]

    element.contact_list = contact_lists(:zombo)
    element.should be_valid
  end

  describe '#toggle_paused!' do
    fixtures :site_elements

    let(:site_element) { site_elements(:zombo_traffic) }

    it 'toggles an element from paused to unpaused' do
      expect {
        site_element.toggle_paused!
      }.to change(site_element, :paused?).from(false).to(true)
    end

    it 'toggles an element from unpaused to paused' do
      site_element.update_attribute :paused, true

      expect {
        site_element.toggle_paused!
      }.to change(site_element, :paused?).from(true).to(false)
    end
  end
end
