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
      @site.script_uninstalled_at = nil
    end

    it "is true if script is installed according to db, and not still installed according to api" do
      @site.script_installed_at = 1.week.ago
      @site.stub(script_installed_api?: true)

      @site.has_script_installed?.should be_true
      @site.script_installed_at.should be_present
      @site.script_uninstalled_at.should be_nil
    end

    it "is false if not installed according to db, and not yet installed according to api" do
      @site.script_installed_at = nil
      @site.stub(script_installed_api?: false)

      @site.has_script_installed?.should be_false
      @site.script_installed_at.should be_nil
      @site.script_uninstalled_at.should be_nil
    end

    it "is true if not installed according to db, but installed according to api" do
      @site.script_installed_at = nil
      @site.stub(script_installed_api?: true)

      @site.has_script_installed?.should be_true
      @site.script_installed_at.should be_present
      @site.script_uninstalled_at.should be_nil
    end

    it "is false if previously installed, but now uninstalled according to api" do
      @site.script_installed_at = 1.week.ago
      @site.stub(script_installed_api?: false)

      @site.has_script_installed?.should be_false
      @site.script_uninstalled_at.should be_present
    end
  end

  describe "#script_installed_api?" do
    it "is true if there is only one day of data" do
      Hello::DataAPI.should_receive(:lifetime_totals).and_return({"1" => [[1,0]]})
      @site.script_installed_api?.should be_true
    end

    it "is true if there are multiple days of data" do
      Hello::DataAPI.should_receive(:lifetime_totals).and_return({"1" => [[1,0], [2,0]]})
      @site.script_installed_api?.should be_true
    end

    it "is false if the api returns nil" do
      Hello::DataAPI.should_receive(:lifetime_totals).and_return(nil)
      @site.script_installed_api?.should be_false
    end

    it "is false if the api returns an empty hash" do
      Hello::DataAPI.should_receive(:lifetime_totals).and_return({})
      @site.script_installed_api?.should be_false
    end

    it "is true if one element has views but others do not" do
      Hello::DataAPI.should_receive(:lifetime_totals).and_return({
        "1" => [[1, 0],[1, 0],[1, 0],[1, 0],[1, 0],[1, 0],[1, 0],[1, 0]],
        "2" => [[1, 0],[1, 0],[2, 0],[2, 0],[2, 0],[2, 0],[2, 0],[2, 0]]
      })

      @site.script_installed_api?.should be_true
    end

    it "is true if any of the elements have been installed in the last 7 days" do
      Hello::DataAPI.should_receive(:lifetime_totals).and_return({
        "1" => [[1, 0],[1, 0],[1, 0],[1, 0],[1, 0],[1, 0],[1, 0],[1, 0]],
        "2" => [[1, 0],[1, 0]]
      })

      @site.script_installed_api?.should be_true
    end

    it "is false if there have been no views in the last 10 days" do
      Hello::DataAPI.should_receive(:lifetime_totals).and_return({
        "1" => [[1, 0],[1, 0],[1, 0],[1, 0],[1, 0],[1, 0],[1, 0],[1, 0],[1, 0],[1, 0],[1, 0]],
        "2" => [[0, 0]]
      })

      @site.script_installed_api?.should be_false
    end
  end

  describe "#script_installed_db?" do
    before do
      @site.script_installed_at = nil
      @site.script_uninstalled_at = nil
    end

    it "is true if installed_at is set" do
      @site.script_installed_at = 1.week.ago
      @site.script_installed_db?.should be_true
    end

    it "is true if installed_at is more recent than uninstalled_at" do
      @site.script_installed_at = 1.day.ago
      @site.script_uninstalled_at = 1.week.ago

      @site.script_installed_db?.should be_true
    end

    it "is false if uninstalled_at is more recent than installed_at" do
      @site.script_installed_at = 1.week.ago
      @site.script_uninstalled_at = 1.day.ago

      @site.script_installed_db?.should be_false
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

  describe "#url_exists?" do
    it "should return false if no other site exists with the url" do
      Site.create(url: "http://abc.com").url_exists?.should be_false
    end

    it "should return true if another site exists with the url" do
      Site.create(url: "http://abc.com")
      Site.new(url: "http://abc.com").url_exists?.should be_true
    end

    it "should scope to user if user is given" do
      u1 = users(:joey)
      u1.sites.create(url: "http://abc.com")
      u2 = users(:wootie)
      u2.sites.build(url: "http://abc.com").url_exists?(u2).should be_false
    end
  end

  describe "#send_digest_email" do
    it "should not send an email if there are no views in the last week" do
      Hello::DataAPI.stub(:lifetime_totals_by_type).and_return({:total=>Hello::DataAPI::Performance.new([[1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1]])})
      Hello::EmailDigest.should_not_receive(:send)
      @site.send_digest_email
    end

    it "should send an email if there are views in the last week" do
      Hello::DataAPI.stub(:lifetime_totals_by_type).and_return({:total=>Hello::DataAPI::Performance.new([[1, 1], [2, 2]])})
      Hello::EmailDigest.should_receive(:send)
      @site.send_digest_email
    end
  end
end
