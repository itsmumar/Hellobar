require 'spec_helper'

describe SiteElement do
  fixtures :all

  it "belongs to a site through a rule set" do
    bar = site_elements(:zombo_traffic)
    bar.site.should == sites(:zombo)

    bar.rule = nil
    bar.site.should be_nil
  end

  describe "validations" do
    it "requires a contact list if element_subtype is \"email\"" do
      element = site_elements(:zombo_traffic)
      element.should be_valid

      element.contact_list = contact_lists(:zombo)
      element.should be_valid
    end

    describe "#site_is_capable_of_creating_element" do
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
    end

    describe "#redirect_has_url" do
      context "when subtype is email" do
        it "requires a redirect url if redirect is true" do
          element = site_elements(:zombo_email)
          element.settings["redirect"] = 1

          element.save

          element.errors["settings.redirect_url"].
            should include("cannot be blank")
        end

        it "doesn't require a redirect url if redirect is false" do
          element = site_elements(:zombo_email)
          element.settings["redirect"] = 0

          element.save

          element.errors["settings.redirect_url"].should be_empty
        end
      end

      context "when subtype is not email" do
        it "doesn't care about redirect url" do
          element = site_elements(:zombo_traffic)

          element.save

          element.errors["settings.redirect_url"].should be_empty
        end
      end
    end
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
      Hello::DataAPI.stub(:lifetime_totals).with(site, site.site_elements, anything, {}).and_return({element.id.to_s => Hello::DataAPI::Performance.new([[10, 5], [12, 6]]) })
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
      Hello::DataAPI.should_receive(:lifetime_totals).with(site, site.site_elements, anything, {}).and_return({element.id.to_s => Hello::DataAPI::Performance.new([[10, 5], [12, 6]])})
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
