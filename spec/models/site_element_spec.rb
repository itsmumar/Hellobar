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

    element.contact_list = contact_lists(:zombo)
    element.should be_valid
  end

  it 'does not allow an unpersisted element to be created when site is at its limit' do
    site = sites(:free_site)
    capability = double 'capability', at_site_element_limit?: true
    site.stub capabilities: capability

    element = SiteElement.new
    element.stub site: site
    element.valid?

    element.errors[:site].should == ['is currently at its limit to create site elements']
  end

  it 'allows a persisted element to be updated when site is at its limit' do
    site = sites(:free_site)
    capability = double 'capability', at_site_element_limit?: true
    site.stub capabilities: capability

    element = site_elements(:zombo_traffic)
    element.stub site: site

    element.should be_valid
  end

  describe '#toggle_paused!' do
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

  describe "#total_views" do
    let(:site) { sites(:zombo) }
    let(:element) { site_elements(:zombo_traffic) }

    it "returns total views as reported by the data API" do
      Hello::DataAPI.stub(:lifetime_totals).with(site, site.site_elements, anything, {}).and_return({element.id.to_s => [[10, 5], [12, 6]]})
      element.total_views.should == 12
    end

    it "returns zero if no data is returned from the data API" do
      Hello::DataAPI.should_receive(:lifetime_totals).with(site, site.site_elements, anything, {}).and_return({})
      element.total_views.should == 0
    end

    it "returns zero if data API returns nil" do
      Hello::DataAPI.should_receive(:lifetime_totals).with(site, site.site_elements, anything, {}).and_return(nil)
      element.total_views.should == 0
    end
  end

  describe "#total_conversions" do
    let(:site) { sites(:zombo) }
    let(:element) { site_elements(:zombo_traffic) }

    it "returns total views as reported by the data API" do
      Hello::DataAPI.should_receive(:lifetime_totals).with(site, site.site_elements, anything, {}).and_return({element.id.to_s => [[10, 5], [12, 6]]})
      element.total_conversions.should == 6
    end

    it "returns zero if no data is returned from the data API" do
      Hello::DataAPI.should_receive(:lifetime_totals).with(site, site.site_elements, anything, {}).and_return({})
      element.total_conversions.should == 0
    end

    it "returns zero if data API returns nil" do
      Hello::DataAPI.should_receive(:lifetime_totals).with(site, site.site_elements, anything, {}).and_return(nil)
      element.total_conversions.should == 0
    end
  end
end
