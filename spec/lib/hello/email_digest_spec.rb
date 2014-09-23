require "spec_helper"

describe Hello::EmailDigest do
  fixtures :all

  describe "email_name" do
    it "returns the proper name for sites that have a script installed" do
      site = double("site", :created_at => 1.day.ago, :script_installed_at => 1.day.ago)
      Hello::EmailDigest.email_name(site).should == "installed_v1_w1"

      site = double("site", :created_at => 8.days.ago, :script_installed_at => 8.days.ago)
      Hello::EmailDigest.email_name(site).should == "installed_v1_w2"
    end

    it "returns the proper name for sites that don't have a script installed" do
      site = double("site", :created_at => 1.day.ago, :script_installed_at => nil)
      Hello::EmailDigest.email_name(site).should == "not_installed_v1_w1"

      site = double("site", :created_at => 8.days.ago, :script_installed_at => nil)
      Hello::EmailDigest.email_name(site).should == "not_installed_v1_w2"
    end

    it "uses the script_installed_at attribute for determining cohort when installed" do
      site = double("site", :created_at => 8.days.ago, :script_installed_at => 1.day.ago)
      Hello::EmailDigest.email_name(site).should == "installed_v1_w1"
    end
  end

  describe "site_metrics" do
    before(:each) do
      Timecop.freeze(Time.parse("Mon Apr 28 06:30:00 CDT 2014"))

      @site = sites(:zombo)
      @social_bar = site_elements(:zombo_twitter)
      @traffic_bar = site_elements(:zombo_traffic)
      @email_bar = site_elements(:zombo_email)
    end

    after(:each) do
      Timecop.return
    end

    it "does not include lift unless the script has been installed for two full weeks" do
      Hello::DataAPI.stub(:lifetime_totals => {
        @social_bar.id.to_s => [[12, 11], [12, 11]]
      })

      data = Hello::EmailDigest.site_metrics(@site)

      data[:social][:views][:lift].should == nil
      data[:social][:actions][:lift].should == nil
      data[:social][:conversion][:lift].should == nil
    end

    it "does not include data for bar types that haven't been created" do
      Hello::DataAPI.stub(:lifetime_totals => {
        @social_bar.id.to_s => [[12, 11], [12, 11]]
      })

      data = Hello::EmailDigest.site_metrics(@site)

      data[:social].should_not be_nil
      data[:traffic].should be_nil
      data[:email].should be_nil
    end

    it "separates statistics by bar type" do
      Hello::DataAPI.stub(:lifetime_totals => {
        @social_bar.id.to_s => [[12, 11], [12, 11]],
        @traffic_bar.id.to_s => [[56, 55], [90, 88], [90, 88]]
      })

      data = Hello::EmailDigest.site_metrics(@site)

      data[:social][:views][:n].should == 12
      data[:social][:actions][:n].should == 11
      data[:social][:conversion][:n].should be_within(0.01).of(11.0/12)
      data[:traffic][:views][:n].should == 90
      data[:traffic][:actions][:n].should == 88
      data[:traffic][:conversion][:n].should be_within(0.01).of(88.0/90)
      data[:email].should == nil
    end

    it "includes lift data if the script has been installed for two full weeks and there is enough bar data" do
      Hello::DataAPI.stub(:lifetime_totals => {
        @traffic_bar.id.to_s => Array.new(7, [56, 55]) + Array.new(8, [90, 88])
      })

      data = Hello::EmailDigest.site_metrics(@site)

      data[:traffic][:views][:n].should == 34
      data[:traffic][:actions][:n].should == 33
      data[:traffic][:conversion][:n].should be_within(0.01).of(33.0/34)
      data[:traffic][:views][:lift].should be_within(0.01).of((34 - 56) / 56.0)
      data[:traffic][:actions][:lift].should be_within(0.01).of((33 - 55) / 55.0)
      data[:traffic][:conversion][:lift].should be_within(0.01).of(((33.0/34) - (55.0/56)) / (55.0/56))
    end

    it "totals this week's data" do
      Hello::DataAPI.stub(:lifetime_totals => {
        @social_bar.id.to_s => Array.new(7, [0, 0]) + Array.new(8, [12, 11]),
        @traffic_bar.id.to_s => Array.new(7, [56, 55]) + Array.new(8, [90, 88])
      })

      data = Hello::EmailDigest.site_metrics(@site)

      data[:total][:views][:n].should == 46
      data[:total][:actions][:n].should == 44
      data[:total][:conversion][:n].should be_within(0.01).of(44.0/46)
      data[:total][:views][:lift].should be_within(0.01).of((46 - 56) / 56.0)
      data[:total][:actions][:lift].should be_within(0.01).of((44 - 55) / 55.0)
      data[:total][:conversion][:lift].should be_within(0.01).of(((44.0/46) - (55.0/56)) / (55.0 / 56))
    end

    it "handles no bar data" do
      Hello::DataAPI.stub(:lifetime_totals => {})

      data = Hello::EmailDigest.site_metrics(@site)

      data[:social].should == nil
      data[:traffic].should == nil
      data[:email].should == nil
      data[:total].should == nil
    end

    it "works when there have been no views or conversions this week" do
      Hello::DataAPI.stub(:lifetime_totals => {
        @email_bar.id.to_s => Array.new(8, [0, 0]),
        @traffic_bar.id.to_s => Array.new(10, [20, 10])
      })

      data = Hello::EmailDigest.site_metrics(@site)

      data[:total][:views][:n].should == 0
    end

    it "computes lift totals correctly if there were no conversions last week" do
      Hello::DataAPI.stub(:lifetime_totals => {
        @email_bar.id.to_s => Array.new(7, [10, 0]) + Array.new(8, [20, 4])
      })

      data = Hello::EmailDigest.site_metrics(@site)

      data[:total][:views][:lift].should == 0.0
      data[:total][:actions][:lift].should == nil
      data[:total][:conversion][:lift].should == nil
    end
  end

  describe "create_bar_cta" do
    before do
      @metrics = {
        :traffic => {:conversion => {:n => 0.8}},
        :email =>   {:conversion => {:n => 0.4}},
        :social =>  {:conversion => {:n => 0.2}}
      }

      @url = ""
      @site = sites(:polymathic)
    end

    it "suggests creation of a social bar if there aren't any" do
      @site.rules.first.site_elements = [
        SiteElement.new.tap{|b| b.element_subtype = "traffic"},
        SiteElement.new.tap{|b| b.element_subtype = "email"; b.contact_list = contact_lists(:zombo)}
      ]

      @metrics[:social] = nil

      Hello::EmailDigest.create_bar_cta(@site, @metrics, @url).should =~ /gaining followers/
    end

    it "suggests creation of an email bar if there aren't any" do
      @site.rules.first.site_elements = [
        SiteElement.new.tap{|b| b.element_subtype = "traffic"},
        SiteElement.new.tap{|b| b.element_subtype = "social/tweet_on_twitter"}
      ]

      @metrics[:email] = nil

      Hello::EmailDigest.create_bar_cta(@site, @metrics, @url).should =~ /collecting email/
    end

    it "suggests creation of a traffic bar if there aren't any" do
      @site.rules.first.site_elements = [
        SiteElement.new.tap{|b| b.element_subtype = "social/tweet_on_twitter"},
        SiteElement.new.tap{|b| b.element_subtype = "email"; b.contact_list = contact_lists(:zombo)}
      ]

      @metrics[:traffic] = nil

      Hello::EmailDigest.create_bar_cta(@site, @metrics, @url).should =~ /driving traffic/
    end

    it "suggests creation of a second bar of the worst-performing type, if at least one of each bar already exists" do
      @site.rules.first.site_elements = [
        SiteElement.new.tap{|b| b.element_subtype = "social/follow_on_twitter"},
        SiteElement.new.tap{|b| b.element_subtype = "email"; b.contact_list = contact_lists(:zombo)},
        SiteElement.new.tap{|b| b.element_subtype = "traffic"}
      ]

      Hello::EmailDigest.create_bar_cta(@site, @metrics, @url).should =~ /Start testing more social bars/
    end

    it "uses dynamic bar units in 'worst-performing' CTA" do
      @site.rules.first.site_elements = [
        SiteElement.new.tap{|b| b.element_subtype = "social/follow_on_twitter"},
        SiteElement.new.tap{|b| b.element_subtype = "email"; b.contact_list = contact_lists(:zombo)},
        SiteElement.new.tap{|b| b.element_subtype = "traffic"}
      ]

      Hello::EmailDigest.create_bar_cta(@site, @metrics, @url).should =~ /get more followers/
    end
  end

  describe "installed_params" do
    before do
      @metrics = {
        :total => {:views => {:n => 3570, :lift => 50.0}, :actions => {:n => 357, :lift => 50.0}, :conversion => {:n => 0.1, :lift => 0.0}},
        :email => nil,
        :social => nil,
        :traffic => {:views => {:n => 3570, :lift => 50.0}, :actions => {:n => 357, :lift => 50.0}, :conversion => {:n => 0.1, :lift => 0.0}}
      }

      @site = sites(:zombo)
      @user = @site.owner
    end

    it "generates the params for the 'installed' version of the digest" do
      params = Hello::EmailDigest.installed_params(@site, @user, @metrics, "installed_v1_w1")
      params[:site_url].should == "zombo.com"
    end
  end

  describe "not_installed_params" do
    before do
      @site = sites(:zombo)
      @user = @site.owner
    end

    it "generates the params for the 'installed' version of the digest" do
      params = Hello::EmailDigest.not_installed_params(@site, @user, "not_installed_v1_w1")
      params[:site_url].should == "zombo.com"
    end
  end
end
