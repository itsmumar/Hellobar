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
    it "returns the right message if element has no conversion data yet" do
      element = site_elements(:zombo_traffic)
      message = recent_activity_message(element, {})
      message.should =~ /hasn't resulted in any clicks yet/
    end

    it "returns the right message if element has 0 conversions" do
      element = site_elements(:zombo_traffic)
      totals = {element.id.to_s => [[5, 0]]}
      message = recent_activity_message(element, totals)
      message.should =~ /hasn't resulted in any clicks yet/
    end

    it "uses the right noun to describe conversions, depending on subtype" do
      element = site_elements(:zombo_traffic)
      recent_activity_message(element, {}).should =~ /in any clicks yet/

      element = site_elements(:zombo_email)
      recent_activity_message(element, {}).should =~ /in any emails collected yet/

      element = site_elements(:zombo_twitter)
      recent_activity_message(element, {}).should =~ /in any tweets yet/

      element = site_elements(:zombo_facebook)
      recent_activity_message(element, {}).should =~ /in any likes yet/
    end

    it "returns the right message when there are conversions" do
      element = site_elements(:zombo_traffic)
      recent_activity_message(element, {element.id.to_s => [[10, 5]]}).should =~ /resulted in 5 clicks/

      element = site_elements(:zombo_email)
      recent_activity_message(element, {element.id.to_s => [[10, 5]]}).should =~ /resulted in 5 emails collected/

      element = site_elements(:zombo_twitter)
      recent_activity_message(element, {element.id.to_s => [[10, 5]]}).should =~ /resulted in 5 tweets/

      element = site_elements(:zombo_facebook)
      recent_activity_message(element, {element.id.to_s => [[10, 5]]}).should =~ /resulted in 5 likes/
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
