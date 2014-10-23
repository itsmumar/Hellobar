require 'spec_helper'

describe SiteElementsHelper do
  fixtures :all

  describe "site_element_subtypes_for_site" do
    fixtures :all

    let(:site) { sites(:zombo) }

    context "none" do
      before do
        site.stub(:site_elements => [])
      end

      it "returns valid types" do
        expect(helper.site_element_subtypes_for_site(site)).to eq([])
      end
    end

    context "traffic" do
      before do
        site.stub(:site_elements => [site_elements(:zombo_traffic)])
      end

      it "returns valid types" do
        expect(helper.site_element_subtypes_for_site(site)).to eq(["traffic"])
      end
    end

    context "email" do
      before do
        site.stub(:site_elements => [site_elements(:zombo_email)])
      end

      it "returns valid types" do
        expect(helper.site_element_subtypes_for_site(site)).to eq(["email"])
      end
    end

    context "multiple" do
      before do
        site.stub(:site_elements => [site_elements(:zombo_traffic), site_elements(:zombo_email)])
      end

      it "returns valid types" do
        expect(helper.site_element_subtypes_for_site(site)).to match_array(["traffic", "email"])
      end
    end
  end

  describe "#recent_activity_message" do
    context "with no conversions" do
      it "uses the right noun to describe conversions for traffic elements" do
        element = site_elements(:zombo_traffic)
        element.stub(:total_conversions => 0, :total_views => 0)
        recent_activity_message(element).should =~ /hasn't resulted in any clicks yet/
      end

      it "uses the right noun to describe conversions for email elements" do
        element = site_elements(:zombo_email)
        element.stub(:total_conversions => 0, :total_views => 0)
        recent_activity_message(element).should =~ /hasn't resulted in any emails collected yet/
      end

      it "uses the right noun to describe conversions for twitter elements" do
        element = site_elements(:zombo_twitter)
        element.stub(:total_conversions => 0, :total_views => 0)
        recent_activity_message(element).should =~ /hasn't resulted in any tweets yet/
      end

      it "uses the right noun to describe conversions for facebook elements" do
        element = site_elements(:zombo_facebook)
        element.stub(:total_conversions => 0, :total_views => 0)
        recent_activity_message(element).should =~ /hasn't resulted in any likes yet/
      end
    end

    it "doesn't pluralize when there was only one conversion" do
      element = site_elements(:zombo_email)
      element.stub(:total_conversions => 1, :total_views => 1)
      recent_activity_message(element).should =~ /resulted in 1 email collected/
    end

    context "with multiple conversions" do
      it "returns the correct message for traffic elements" do
        element = site_elements(:zombo_traffic)
        element.stub(:total_conversions => 5, :total_views => 5)
        recent_activity_message(element).should =~ /resulted in 5 clicks/
      end

      it "returns the correct message for email elements" do
        element = site_elements(:zombo_email)
        element.stub(:total_conversions => 5, :total_views => 5)
        recent_activity_message(element).should =~ /resulted in 5 emails collected/
      end

      it "returns the correct message for twitter elements" do
        Hello::DataAPI.stub(:lifetime_totals => {})
        element = site_elements(:zombo_twitter)
        element.stub(:total_conversions => 5, :total_views => 5)
        recent_activity_message(element).should =~ /resulted in 5 tweets/
      end

      it "returns the correct message for facebook elements" do
        Hello::DataAPI.stub(:lifetime_totals => {})
        element = site_elements(:zombo_facebook)
        element.stub(:total_conversions => 5, :total_views => 5)
        recent_activity_message(element).should =~ /resulted in 5 likes/
      end
    end

    it "shows the conversion rate relative to other elements of the same type" do
      element = site_elements(:zombo_twitter)
      Hello::DataAPI.stub(:lifetime_totals => {
        element.id.to_s => [[10, 5]],
        site_elements(:zombo_facebook).id.to_s => [[10, 1]]
      })

      recent_activity_message(element).should =~ /converting 400\.0% better than your other social bars/
    end

    it "doesnt return the conversion rate when it is Infinite" do
      element = site_elements(:zombo_twitter)
      Hello::DataAPI.stub(:lifetime_totals => {
        element.id.to_s => [[0, 5]],
        site_elements(:zombo_facebook).id.to_s => [[10, 1]]
      })

      recent_activity_message(element).should_not =~ /converting (.+) better than your other social bars/
    end
  end

  describe "site_element_activity_units" do
    before(:each) do
      @bars = {
        :traffic =>                 SiteElement.new(:element_subtype => "traffic"),
        :email =>                   SiteElement.new(:element_subtype => "email"),
        :tweet_on_twitter =>        SiteElement.new(:element_subtype => "social/tweet_on_twitter"),
        :follow_on_twitter =>       SiteElement.new(:element_subtype => "social/follow_on_twitter"),
        :like_on_facebook =>        SiteElement.new(:element_subtype => "social/like_on_facebook"),
        :share_on_linkedin =>       SiteElement.new(:element_subtype => "social/share_on_linkedin"),
        :plus_one_on_google_plus => SiteElement.new(:element_subtype => "social/plus_one_on_google_plus"),
        :pin_on_pinterest =>        SiteElement.new(:element_subtype => "social/pin_on_pinterest"),
        :follow_on_pinterest =>     SiteElement.new(:element_subtype => "social/follow_on_pinterest"),
        :share_on_buffer =>         SiteElement.new(:element_subtype => "social/share_on_buffer")
      }
    end

    it "returns the correct units for all bar types" do
      site_element_activity_units(@bars[:traffic]).should == "click"
      site_element_activity_units(@bars[:email]).should == "email"
      site_element_activity_units(@bars[:tweet_on_twitter]).should == "tweet"
      site_element_activity_units(@bars[:follow_on_twitter]).should == "follower"
      site_element_activity_units(@bars[:like_on_facebook]).should == "like"
      site_element_activity_units(@bars[:share_on_linkedin]).should == "share"
      site_element_activity_units(@bars[:plus_one_on_google_plus]).should == "plus one"
      site_element_activity_units(@bars[:pin_on_pinterest]).should == "pin"
      site_element_activity_units(@bars[:follow_on_pinterest]).should == "follower"
      site_element_activity_units(@bars[:share_on_buffer]).should == "share"
    end

    it "optionally adds an appropriate verb" do
      site_element_activity_units(@bars[:traffic], :verb => true).should == "click"
      site_element_activity_units(@bars[:email], :verb => true).should == "email collected"
      site_element_activity_units(@bars[:tweet_on_twitter], :verb => true).should == "tweet"
      site_element_activity_units(@bars[:follow_on_twitter], :verb => true).should == "follower gained"
      site_element_activity_units(@bars[:like_on_facebook], :verb => true).should == "like"
      site_element_activity_units(@bars[:share_on_linkedin], :verb => true).should == "share"
      site_element_activity_units(@bars[:plus_one_on_google_plus], :verb => true).should == "plus one"
      site_element_activity_units(@bars[:pin_on_pinterest], :verb => true).should == "pin"
      site_element_activity_units(@bars[:follow_on_pinterest], :verb => true).should == "follower gained"
      site_element_activity_units(@bars[:share_on_buffer], :verb => true).should == "share"
      site_element_activity_units([@bars[:traffic], @bars[:email]], :verb => true).should == "conversion"
    end

    it "pluralizes correctly with verb" do
      site_element_activity_units(@bars[:traffic], :plural => true, :verb => true).should == "clicks"
      site_element_activity_units(@bars[:email], :plural => true, :verb => true).should == "emails collected"
      site_element_activity_units(@bars[:tweet_on_twitter], :plural => true, :verb => true).should == "tweets"
      site_element_activity_units(@bars[:follow_on_twitter], :plural => true, :verb => true).should == "followers gained"
      site_element_activity_units(@bars[:like_on_facebook], :plural => true, :verb => true).should == "likes"
      site_element_activity_units(@bars[:share_on_linkedin], :plural => true, :verb => true).should == "shares"
      site_element_activity_units(@bars[:plus_one_on_google_plus], :plural => true, :verb => true).should == "plus ones"
      site_element_activity_units(@bars[:pin_on_pinterest], :plural => true, :verb => true).should == "pins"
      site_element_activity_units(@bars[:follow_on_pinterest], :plural => true, :verb => true).should == "followers gained"
      site_element_activity_units(@bars[:share_on_buffer], :plural => true, :verb => true).should == "shares"
      site_element_activity_units([@bars[:traffic], @bars[:email]], :plural => true, :verb => true).should == "conversions"
    end

    it "optionally pluralizes the units" do
      site_element_activity_units(@bars[:traffic], :plural => true).should == "clicks"
      site_element_activity_units(@bars[:email], :plural => true).should == "emails"
      site_element_activity_units(@bars[:tweet_on_twitter], :plural => true).should == "tweets"
      site_element_activity_units(@bars[:follow_on_twitter], :plural => true).should == "followers"
      site_element_activity_units(@bars[:like_on_facebook], :plural => true).should == "likes"
      site_element_activity_units(@bars[:share_on_linkedin], :plural => true).should == "shares"
      site_element_activity_units(@bars[:plus_one_on_google_plus], :plural => true).should == "plus ones"
      site_element_activity_units(@bars[:pin_on_pinterest], :plural => true).should == "pins"
      site_element_activity_units(@bars[:follow_on_pinterest], :plural => true).should == "followers"
      site_element_activity_units(@bars[:share_on_buffer], :plural => true).should == "shares"
    end

    it "consolidates multiple bar types into a unit that makes sense for all" do
      other_traffic_bar = SiteElement.new(:element_subtype => "traffic")
      site_element_activity_units([other_traffic_bar, @bars[:traffic]]).should == "click"
      site_element_activity_units([other_traffic_bar, @bars[:traffic], @bars[:email]]).should == "conversion"
    end
  end
end
