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
      @social_bar = bars(:zombo_twitter)
      @traffic_bar = bars(:zombo_traffic)
      @email_bar = bars(:zombo_email)
    end

    after(:each) do
      Timecop.return
    end

    it "does not include lift unless the script has been installed for two full weeks" do
      Hello::BarData.should_receive(:get_over_time_data).and_return([
        Hello::BarData.new(@site.id, @social_bar.id, 1.day.ago.strftime("%Y%m%d").to_i, 12, 11)
      ])

      data = Hello::EmailDigest.site_metrics(@site)

      data[:social][:views][:lift].should == nil
      data[:social][:actions][:lift].should == nil
      data[:social][:conversion][:lift].should == nil
    end

    it "does not include data for bar types that haven't been created" do
      Hello::BarData.should_receive(:get_over_time_data).and_return([
        Hello::BarData.new(@site.id, @social_bar.id, 1.day.ago.strftime("%Y%m%d").to_i, 12, 11)
      ])

      data = Hello::EmailDigest.site_metrics(@site)

      data[:traffic].should == nil
      data[:email].should == nil
    end

    it "separates statistics by bar type" do
      Hello::BarData.should_receive(:get_over_time_data).and_return([
        Hello::BarData.new(@site.id, @social_bar.id, 1.day.ago.strftime("%Y%m%d").to_i, 12, 11),
        Hello::BarData.new(@site.id, @traffic_bar.id, 1.day.ago.strftime("%Y%m%d").to_i, 34, 33),
        Hello::BarData.new(@site.id, @traffic_bar.id, 2.days.ago.strftime("%Y%m%d").to_i, 56, 55)
      ])

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
      Hello::BarData.should_receive(:get_over_time_data).and_return([
        Hello::BarData.new(@site.id, @traffic_bar.id, 1.day.ago.strftime("%Y%m%d").to_i, 34, 33),
        Hello::BarData.new(@site.id, @traffic_bar.id, 9.days.ago.strftime("%Y%m%d").to_i, 56, 55)
      ])

      @site.script_installed_at = 15.days.ago
      data = Hello::EmailDigest.site_metrics(@site)

      data[:traffic][:views][:n].should == 34
      data[:traffic][:actions][:n].should == 33
      data[:traffic][:conversion][:n].should be_within(0.01).of(33.0/34)
      data[:traffic][:views][:lift].should be_within(0.01).of((34 - 56) / 56.0)
      data[:traffic][:actions][:lift].should be_within(0.01).of((33 - 55) / 55.0)
      data[:traffic][:conversion][:lift].should be_within(0.01).of(((33.0/34) - (55.0/56)) / (55.0/56))
    end

    it "totals this week's data" do
      Hello::BarData.should_receive(:get_over_time_data).and_return([
        Hello::BarData.new(@site.id, @social_bar.id, 1.day.ago.strftime("%Y%m%d").to_i, 12, 11),
        Hello::BarData.new(@site.id, @traffic_bar.id, 1.day.ago.strftime("%Y%m%d").to_i, 34, 33),
        Hello::BarData.new(@site.id, @traffic_bar.id, 8.days.ago.strftime("%Y%m%d").to_i, 56, 55)
      ])

      @site.script_installed_at = 15.days.ago
      data = Hello::EmailDigest.site_metrics(@site)

      data[:total][:views][:n].should == 46
      data[:total][:actions][:n].should == 44
      data[:total][:conversion][:n].should be_within(0.01).of(44.0/46)
      data[:total][:views][:lift].should be_within(0.01).of((46 - 56) / 56.0)
      data[:total][:actions][:lift].should be_within(0.01).of((44 - 55) / 55.0)
      data[:total][:conversion][:lift].should be_within(0.01).of(((44.0/46) - (55.0/56)) / (55.0 / 56))
    end

    it "handles no bar data" do
      Hello::BarData.should_receive(:get_over_time_data).and_return([])

      data = Hello::EmailDigest.site_metrics(@site)

      data[:social].should == nil
      data[:traffic].should == nil
      data[:email].should == nil
      data[:total].should == nil
    end

    it "works when there's data for last week but not this week" do
      Hello::BarData.should_receive(:get_over_time_data).and_return([
        Hello::BarData.new(@site.id, @email_bar.id, 8.days.ago.strftime("%Y%m%d").to_i, 0, 0),
        Hello::BarData.new(@site.id, @traffic_bar.id, 8.days.ago.strftime("%Y%m%d").to_i, 56, 55)
      ])

      @site.script_installed_at = 15.days.ago
      data = Hello::EmailDigest.site_metrics(@site)

      data[:total][:views][:n].should == 0
    end

    it "computes lift totals correctly if there were no conversions last week" do
      Hello::BarData.should_receive(:get_over_time_data).and_return([
        Hello::BarData.new(@site.id, @email_bar.id, 8.days.ago.strftime("%Y%m%d").to_i, 10, 0),
        Hello::BarData.new(@site.id, @email_bar.id, 1.days.ago.strftime("%Y%m%d").to_i, 10, 4)
      ])

      @site.script_installed_at = 15.days.ago
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
      @site.create_default_rule
    end

    it "suggests creation of a social bar if there aren't any" do
      @site.rules.first.bars = [
        Bar.new.tap{|b| b.bar_type = "traffic"},
        Bar.new.tap{|b| b.bar_type = "email"}
      ]

      Hello::EmailDigest.create_bar_cta(@site, @metrics, @url).should =~ /gaining followers/
    end

    it "suggests creation of an email bar if there aren't any" do
      @site.rules.first.bars = [
        Bar.new.tap{|b| b.bar_type = "traffic"},
        Bar.new.tap{|b| b.bar_type = "social/tweet_on_twitter"}
      ]

      Hello::EmailDigest.create_bar_cta(@site, @metrics, @url).should =~ /collecting email/
    end

    it "suggests creation of a traffic bar if there aren't any" do
      @site.rules.first.bars = [
        Bar.new.tap{|b| b.bar_type = "social/tweet_on_twitter"},
        Bar.new.tap{|b| b.bar_type = "email"}
      ]

      Hello::EmailDigest.create_bar_cta(@site, @metrics, @url).should =~ /driving traffic/
    end

    it "suggests creation of a second bar of the worst-performing type, if at least one of each bar already exists" do
      @site.rules.first.bars = [
        Bar.new.tap{|b| b.bar_type = "social/follow_on_twitter"},
        Bar.new.tap{|b| b.bar_type = "email"},
        Bar.new.tap{|b| b.bar_type = "traffic"}
      ]

      Hello::EmailDigest.create_bar_cta(@site, @metrics, @url).should =~ /Start testing more social bars/
    end

    it "uses dynamic bar units in 'worst-performing' CTA" do
      @site.rules.first.bars = [
        Bar.new.tap{|b| b.bar_type = "social/follow_on_twitter"},
        Bar.new.tap{|b| b.bar_type = "email"},
        Bar.new.tap{|b| b.bar_type = "traffic"}
      ]

      Hello::EmailDigest.create_bar_cta(@site, @metrics, @url).should =~ /get more followers/
    end
  end
end
