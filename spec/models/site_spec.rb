require 'spec_helper'

describe Site do
  fixtures :all

  before(:each) do
    @site = sites(:zombo)
  end

  it_behaves_like "an object with a valid url"

  it "is able to access its owner" do
    expect(@site.owners.first).to eq(users(:joey))
  end

  describe "#create_default_rule" do
    it "creates a rule for the site" do
      site = sites(:horsebike)

      expect {
        site.create_default_rule
      }.to change { site.rules.count }.by(1)
    end
  end

  describe "#is_free?" do
    it "is true initially" do
      site = Site.new
      expect(site.is_free?).to be_true
    end

    it "is true for sites with a free-level subscriptions" do
      expect(sites(:horsebike).is_free?).to be_true
    end

    it "is true for sites with a free-plus-level subscriptions" do
      site = sites(:horsebike)
      site.change_subscription(Subscription::FreePlus.new(schedule: 'monthly'))
      expect(site.is_free?).to be_true
    end

    it "is false for pro sites" do
      expect(sites(:pro_site).is_free?).to be_false
    end

    it "is false for pro comped sites" do
      site = sites(:horsebike)
      site.change_subscription(Subscription::ProComped.new(schedule: 'monthly'))
      expect(site.is_free?).to be_false
    end
  end

  describe "#change_subscription" do
    it "runs set_branding_on_site_elements after changing subscription" do
      site = sites(:horsebike)
      expect(site).to receive(:set_branding_on_site_elements)
      site.change_subscription(Subscription::ProComped.new(schedule: 'monthly'))
    end

    it "applies the discount when changing subscription to pro and it belongs to a discount tier" do
      user = create(:user)
      bills = []

      zero_discount_subs = Subscription::Pro.defaults[:discounts].detect { |x| x.tier == 0 }.slots
      zero_discount_subs.times do
        bill = create(:pro_bill, status: :paid)
        bill.site.users << user
        user.reload
        bill.subscription.payment_method.update(user: user)
        bill.update(discount: bill.calculate_discount)
      end

      site = create(:site, users: [user])
      site.change_subscription(Subscription::Pro.new(schedule: 'monthly'), user.payment_methods.first)
      expect(site.bills.paid.first.discount > 0).to be(true)
    end
  end

  describe "url formatting" do
    it "adds the protocol if not present" do
      site = Site.new(:url => "zombo.com")
      site.valid?
      expect(site.url).to eq("http://zombo.com")
    end

    it "uses the supplied protocol if present" do
      site = Site.new(:url => "https://zombo.com")
      site.valid?
      expect(site.url).to eq("https://zombo.com")

      site = Site.new(:url => "http://zombo.com")
      site.valid?
      expect(site.url).to eq("http://zombo.com")
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
        expect(site.url).to eq("http://zombo.com")
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
        expect(site.errors[:url]).to be_empty
      end
    end

    it "is invalid without a properly-formatted url" do
      site = Site.new(:url => "my great website dot com")
      expect(site).not_to be_valid
      expect(site.errors[:url]).not_to be_empty
    end

    it "is invalid without a url" do
      site = Site.new(:url => "")
      expect(site).not_to be_valid
      expect(site.errors[:url]).not_to be_empty
    end

    it "doesn't try to format a blank URL" do
      site = Site.new(:url => "")
      expect(site).not_to be_valid
      expect(site.url).to be_blank
    end
  end

  describe "#script_content" do
    it "generates the contents of the script for a site" do
      Hello::DataAPI.stub(:lifetime_totals => nil)
      script = @site.script_content(false)

      expect(script).to match(/HB_SITE_ID/)
      expect(script).to include(@site.site_elements.first.id.to_s)
    end

    it "generates the compressed contents of the script for a site" do
      Hello::DataAPI.stub(:lifetime_totals => nil)
      script = @site.script_content

      expect(script).to match(/HB_SITE_ID/)
      expect(script).to include(@site.site_elements.first.id.to_s)
    end
  end

  describe "#generate_script" do
    it "delegates :generate_static_assets to delay" do
      expect(@site).to receive(:delay).with(:generate_static_assets, anything)
      @site.generate_script
    end

    it "calls generate_static_assets if immediately option is specified" do
      expect(@site).to receive(:generate_static_assets)
      @site.generate_script(immediately: true)
    end
  end

  describe "#generate_static_assets" do
    before do
      @mock_storage = double("asset_storage")
      allow(Hello::AssetStorage).to receive(:new).and_return(@mock_storage)
    end

    it "generates and uploads the script content for a site" do
      ScriptGenerator.any_instance.stub(:pro_secret => "asdf")
      Hello::DataAPI.stub(:lifetime_totals => nil)
      script_content = @site.script_content(true)
      script_name = @site.script_name

      mock_storage = double("asset_storage")
      expect(mock_storage).to receive(:create_or_update_file_with_contents).with(script_name, script_content)
      Hello::AssetStorage.stub(:new => mock_storage)

      @site.generate_script
    end

    it "generates scripts for each wordpress bar" do
      site_element = create(:site_element, wordpress_bar_id: 123)
      user = create(:user, wordpress_user_id: 456)
      site_element.site.users << user

      allow_any_instance_of(ScriptGenerator).to receive(:pro_secret).and_return("asdf")
      allow(Hello::DataAPI).to receive(:lifetime_totals).and_return(nil)
      site = site_element.site.reload

      # First, generate for site, then for the site element
      expect(@mock_storage).to receive(:create_or_update_file_with_contents).with(anything, anything).ordered
      expect(@mock_storage).to receive(:create_or_update_file_with_contents).with("#{user.wordpress_user_id}_#{site_element.wordpress_bar_id}.js", anything).ordered
      site.send(:generate_static_assets)
    end
  end

  it "blanks-out the site script when destroyed" do
    mock_storage = double("asset_storage")
    expect(mock_storage).to receive(:create_or_update_file_with_contents).with(@site.script_name, "")
    Hello::AssetStorage.stub(:new => mock_storage)

    @site.destroy
  end

  it "should soft-delete" do
    allow(@site).to receive(:generate_static_assets)
    @site.destroy
    expect(Site.only_deleted).to include(@site)
  end

  describe "#has_script_installed?" do
    before do
      @site.script_installed_at = nil
      @site.script_uninstalled_at = nil
    end

    it "is true if script is installed according to db, and not still installed according to api" do
      @site.script_installed_at = 1.week.ago
      @site.stub(script_installed_api?: true)

      expect(@site.has_script_installed?).to be_true
      expect(@site.script_installed_at).to be_present
      expect(@site.script_uninstalled_at).to be_nil
    end

    it "is false if not installed according to db, and not yet installed according to api" do
      @site.script_installed_at = nil
      @site.stub(script_installed_api?: false)

      expect(@site.has_script_installed?).to be_false
      expect(@site.script_installed_at).to be_nil
      expect(@site.script_uninstalled_at).to be_nil
    end

    it "is true if not installed according to db, but installed according to api" do
      @site.script_installed_at = nil
      @site.stub(script_installed_api?: true)

      expect(@site.has_script_installed?).to be_true
      expect(@site.script_installed_at).to be_present
      expect(@site.script_uninstalled_at).to be_nil
    end

    it "is false if previously installed, but now uninstalled according to api" do
      @site.script_installed_at = 1.week.ago
      @site.stub(script_installed_api?: false)

      expect(@site.has_script_installed?).to be_false
      expect(@site.script_uninstalled_at).to be_present
    end
  end

  describe "#script_installed_api?" do
    it "is true if there is only one day of data" do
      expect(Hello::DataAPI).to receive(:lifetime_totals).and_return({"1" => [[1,0]]})
      expect(@site.script_installed_api?).to be_true
    end

    it "is true if there are multiple days of data" do
      expect(Hello::DataAPI).to receive(:lifetime_totals).and_return({"1" => [[1,0], [2,0]]})
      expect(@site.script_installed_api?).to be_true
    end

    it "is false if the api returns nil" do
      expect(Hello::DataAPI).to receive(:lifetime_totals).and_return(nil)
      expect(@site.script_installed_api?).to be_false
    end

    it "is false if the api returns an empty hash" do
      expect(Hello::DataAPI).to receive(:lifetime_totals).and_return({})
      expect(@site.script_installed_api?).to be_false
    end

    it "is true if one element has views but others do not" do
      expect(Hello::DataAPI).to receive(:lifetime_totals).and_return({
        "1" => [[1, 0],[1, 0],[1, 0],[1, 0],[1, 0],[1, 0],[1, 0],[1, 0]],
        "2" => [[1, 0],[1, 0],[2, 0],[2, 0],[2, 0],[2, 0],[2, 0],[2, 0]]
      })

      expect(@site.script_installed_api?).to be_true
    end

    it "is true if any of the elements have been installed in the last 7 days" do
      expect(Hello::DataAPI).to receive(:lifetime_totals).and_return({
        "1" => [[1, 0],[1, 0],[1, 0],[1, 0],[1, 0],[1, 0],[1, 0],[1, 0]],
        "2" => [[1, 0],[1, 0]]
      })

      expect(@site.script_installed_api?).to be_true
    end

    it "is false if there have been no views in the last 10 days" do
      expect(Hello::DataAPI).to receive(:lifetime_totals).and_return({
        "1" => [[1, 0],[1, 0],[1, 0],[1, 0],[1, 0],[1, 0],[1, 0],[1, 0],[1, 0],[1, 0],[1, 0]],
        "2" => [[0, 0]]
      })

      expect(@site.script_installed_api?).to be_false
    end
  end

  describe "#script_installed_db?" do
    before do
      @site.script_installed_at = nil
      @site.script_uninstalled_at = nil
    end

    it "is true if installed_at is set" do
      @site.script_installed_at = 1.week.ago
      expect(@site.script_installed_db?).to be_true
    end

    it "is true if installed_at is more recent than uninstalled_at" do
      @site.script_installed_at = 1.day.ago
      @site.script_uninstalled_at = 1.week.ago

      expect(@site.script_installed_db?).to be_true
    end

    it "is false if uninstalled_at is more recent than installed_at" do
      @site.script_installed_at = 1.week.ago
      @site.script_uninstalled_at = 1.day.ago

      expect(@site.script_installed_db?).to be_false
    end
  end

  describe "calculate_bill" do
    include ActiveSupport::Testing::TimeHelpers

    context "trial_period is specified" do
      it "should set the bill amount to 0" do
        sub = subscriptions(:zombo_subscription)
        bill = sub.site.send(:calculate_bill, sub, true, 20.day)
        expect(bill.amount).to eq(0)
      end

      it "should set the end_at of the bill to the current time + the trial period" do
        sub = subscriptions(:zombo_subscription)
        travel_to Time.now do
          bill = sub.site.send(:calculate_bill, sub, true, 20.day)
          expect(bill.end_date).to eq(Time.now + 20.day)
        end
      end
    end

    context "trial_period is not specified" do
      it "should set the bill amount to subscription.amount" do
        sub = subscriptions(:zombo_subscription)
        bill = sub.site.send(:calculate_bill, sub, true)
        expect(bill.amount).to eq(sub.amount)
      end

      it "should set the bill end_date to " do
        sub = subscriptions(:zombo_subscription)
        travel_to Time.current do
          bill = sub.site.send(:calculate_bill, sub, true)
          expect(bill.end_date).to eq(Bill::Recurring.next_month(Time.current))
        end
      end
    end
  end

  describe "#url_exists?" do
    it "should return false if no other site exists with the url" do
      expect(Site.create(url: "http://abc.com").url_exists?).to be_false
    end

    it "should return true if another site exists with the url" do
      Site.create(url: "http://abc.com")
      expect(Site.new(url: "http://abc.com").url_exists?).to be_true
    end

    it "should scope to user if user is given" do
      u1 = users(:joey)
      u1.sites.create(url: "http://abc.com")
      u2 = users(:wootie)
      expect(u2.sites.build(url: "http://abc.com").url_exists?(u2)).to be_false
    end
  end

  describe "#set_branding_on_site_elements" do
    it "should set branding based on the current subscription capabilities" do
      sub = subscriptions(:pro_subscription)
      se = site_elements(:zombo_traffic)
      se.rule = sub.site.rules.first
      se.show_branding = true
      se.save
      sub.site.send(:set_branding_on_site_elements)
      expect(se.reload.show_branding).to be_false
    end

    it "should set branding based on the current subscription capabilities" do
      sub = subscriptions(:free_subscription)
      se = site_elements(:zombo_traffic)
      se.rule = sub.site.rules.first
      se.show_branding = true
      se.save
      sub.site.send(:set_branding_on_site_elements)
      expect(se.reload.show_branding).to be_true
    end
  end

  describe "#show_in_bar_ads?" do
    context "ad factor 1.0" do
      let(:passing_site) do
        sites(:free_site).tap do |passing_site|
          passing_site.url = "http://zombo.com"
        end
      end

      before do
        @original_config = Site.in_bar_ads_config
        Site.in_bar_ads_config = {
          test_fraction: 1.0,
          show_to_fraction: 1.0 # show all bars to all people that pass the other restrictions
        }
      end

      after do
        Site.in_bar_ads_config = @original_config
      end

      context "should not show" do
        it "if the bar is not free" do
          allow(passing_site).to receive(:is_free?).at_least(:once).and_return(false)
          expect(passing_site.show_in_bar_ads?).to eq false
        end

        it "if the url is on blacklist" do
          Site.in_bar_ads_config = {
            url_blacklist: ["asdf.com"]
          }
          allow(passing_site).to receive(:url).at_least(:once).and_return("asdf.com")
          expect(passing_site.show_in_bar_ads?).to eq false
        end
      end

      context "should show" do
        it "if the bar is free" do
          expect(Site.in_bar_ads_config[:show_to_fraction]).to eq 1.0
          expect(passing_site.show_in_bar_ads?).to eq true
        end
      end
    end
  end

  describe "#find_by_script" do
    it "should return the site if the script name matches" do
      site = create(:site)
      expect(Site.find_by_script(site.script_name)).to eq(site)
    end

    it "should return nil if no site exists with that script" do
      allow(Site).to receive(:maximum).and_return(10) # so that it doesn't run forever
      expect(Site.find_by_script("foo")).to be_nil
    end
  end
end
