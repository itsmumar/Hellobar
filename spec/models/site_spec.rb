require 'spec_helper'

describe Site do
  fixtures :all

  before(:each) do
    @site = sites(:zombo)
  end

  it_behaves_like "an object with a valid url"

  it "is able to access its owner" do
    @site.owner.should == users(:joey)
  end

  it "#is_free? is true initially" do
    site = Site.new
    site.is_free?.should be_true
  end

  it "#is_free? is true for sites with a free-level subscriptions" do
    sites(:horsebike).is_free?.should be_true
  end

  it "#is_free? is true for sites with a free-plus-level subscriptions" do
    site = sites(:horsebike)
    site.change_subscription(Subscription::FreePlus.new(schedule: 'monthly'))
    site.is_free?.should be_true
  end

  it "#is_free? is false for pro sites" do
    sites(:pro_site).is_free?.should be_false
  end

  it "#is_free? is false for pro comped sites" do
    site = sites(:horsebike)
    site.change_subscription(Subscription::ProComped.new(schedule: 'monthly'))
    site.is_free?.should be_false
  end

  describe "url formatting" do
    it "adds the protocol if not present" do
      site = Site.new(:url => "zombo.com")
      site.valid?
      site.url.should == "http://zombo.com"
    end

    it "uses the supplied protocol if present" do
      site = Site.new(:url => "https://zombo.com")
      site.valid?
      site.url.should == "https://zombo.com"

      site = Site.new(:url => "http://zombo.com")
      site.valid?
      site.url.should == "http://zombo.com"
    end

    it "removes the path, if provided" do
      urls = %w(
        zombo.com/welcometozombocom
        zombo.com/anythingispossible?at=zombocom
        zombo.com?theonlylimit=yourimagination&at=zombocom#welcome
      )

      urls.each do |url|
        site = Site.new(:url => url)
        site.valid?
        site.url.should == "http://zombo.com"
      end
    end

    it "accepts valid inputs" do
      urls = %w(
        zombo.com
        http://zombo.com/
        http://zombo.com/welcome
        http://zombo2.com/welcome
        horse.bike
      )

      urls.each do |url|
        site = Site.new(:url => url)
        site.valid?
        site.errors[:url].should be_empty
      end
    end

    it "is invalid without a properly-formatted url" do
      site = Site.new(:url => "my great website dot com")
      site.should_not be_valid
      site.errors[:url].should_not be_empty
    end

    it "is invalid without a url" do
      site = Site.new(:url => "")
      site.should_not be_valid
      site.errors[:url].should_not be_empty
    end

    it "doesn't try to format a blank URL" do
      site = Site.new(:url => "")
      site.should_not be_valid
      site.url.should be_blank
    end
  end

  describe "#script_content" do
    it "generates the contents of the script for a site" do
      Hello::DataAPI.stub(:lifetime_totals => nil)
      script = @site.script_content(false)

      script.should =~ /HB_SITE_ID/
      script.should include(@site.site_elements.first.id.to_s)
    end

    it "generates the compressed contents of the script for a site" do
      Hello::DataAPI.stub(:lifetime_totals => nil)
      script = @site.script_content

      script.should =~ /HB_SITE_ID/
      script.should include(@site.site_elements.first.id.to_s)
    end
  end

  describe "#generate_static_assets" do
    it "generates and uploads the script content for a site" do
      ScriptGenerator.any_instance.stub(:pro_secret => "asdf")
      Hello::DataAPI.stub(:lifetime_totals => nil)
      script_content = @site.script_content(true)
      script_name = @site.script_name

      mock_storage = double("asset_storage")
      mock_storage.should_receive(:create_or_update_file_with_contents).with(script_name, script_content)
      Hello::AssetStorage.stub(:new => mock_storage)

      @site.generate_script
    end
  end

  it "blanks-out the site script when destroyed" do
    mock_storage = double("asset_storage")
    mock_storage.should_receive(:create_or_update_file_with_contents).with(@site.script_name, "")
    Hello::AssetStorage.stub(:new => mock_storage)

    @site.destroy
  end

  it "should soft-delete" do
    @site.stub(:generate_static_assets)
    @site.destroy
    Site.only_deleted.should include(@site)
  end

  describe "#has_script_installed?" do
    before do
      @site.script_installed_at = nil
    end

    it "is true if script_installed_at is set" do
      @site.script_installed_at = 1.day.ago
      @site.has_script_installed?.should be_true
    end

    it "is false if no site_elements have views" do
      @site.stub(:site_elements => [double("bar", :total_views => 0)])
      @site.has_script_installed?.should be_false
      @site.script_installed_at.should be_nil
    end

    it "is true and sets script_installed_at if at least one site_element has been viewed" do
      @site.stub(:site_elements => [double("bar", :total_views => 1)])
      @site.has_script_installed?.should be_true
      @site.script_installed_at.should_not be_nil
    end
  end

  describe "calculate_bill" do
    include ActiveSupport::Testing::TimeHelpers

    context "trial_period is specified" do
      it "should set the bill amount to 0" do
        sub = subscriptions(:zombo_subscription)
        bill = sub.site.send(:calculate_bill, sub, true, 20.day)
        bill.amount.should == 0
      end

      it "should set the end_at of the bill to the current time + the trial period" do
        sub = subscriptions(:zombo_subscription)
        travel_to Time.now do
          bill = sub.site.send(:calculate_bill, sub, true, 20.day)
          bill.end_date.should == Time.now + 20.day
        end
      end
    end

    context "trial_period is not specified" do
      it "should set the bill amount to subscription.amount" do
        sub = subscriptions(:zombo_subscription)
        bill = sub.site.send(:calculate_bill, sub, true)
        bill.amount.should == sub.amount
      end

      it "should set the bill end_date to " do
        sub = subscriptions(:zombo_subscription)
        travel_to Time.current do
          bill = sub.site.send(:calculate_bill, sub, true)
          bill.end_date.should == Bill::Recurring.next_month(Time.current)
        end
      end
    end
  end
end
