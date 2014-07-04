require 'spec_helper'

describe EmailDigestHelper do
  describe "element_activity_units" do
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
      element_activity_units(@bars[:traffic]).should == "click"
      element_activity_units(@bars[:email]).should == "email"
      element_activity_units(@bars[:tweet_on_twitter]).should == "tweet"
      element_activity_units(@bars[:follow_on_twitter]).should == "follower"
      element_activity_units(@bars[:like_on_facebook]).should == "like"
      element_activity_units(@bars[:share_on_linkedin]).should == "share"
      element_activity_units(@bars[:plus_one_on_google_plus]).should == "plus one"
      element_activity_units(@bars[:pin_on_pinterest]).should == "pin"
      element_activity_units(@bars[:follow_on_pinterest]).should == "follower"
      element_activity_units(@bars[:share_on_buffer]).should == "share"
    end

    # not sure we'll end up needing this. also, verb is awkward for a lot of bar types.
#     it "optionally adds an appropriate verb" do
#       element_activity_units(@bars[:traffic], :verb => true).should == "click recorded"
#       element_activity_units(@bars[:email], :verb => true).should == "email collected"
#       element_activity_units(@bars[:tweet_on_twitter], :verb => true).should == "tweet"
#       element_activity_units(@bars[:follow_on_twitter], :verb => true).should == "follow gained"
#       element_activity_units(@bars[:like_on_facebook], :verb => true).should == "like"
#       element_activity_units(@bars[:share_on_linkedin], :verb => true).should == "share"
#       element_activity_units(@bars[:plus_one_on_google_plus], :verb => true).should == "plus one"
#       element_activity_units(@bars[:pin_on_pinterest], :verb => true).should == "pin"
#       element_activity_units(@bars[:follow_on_pinterest], :verb => true).should == "follow gained"
#       element_activity_units(@bars[:share_on_buffer], :verb => true).should == "share"
#     end
#     it "adjusts the verb to make sense for multiple bars with different units"

    it "optionally pluralizes the units" do
      element_activity_units(@bars[:traffic], :plural => true).should == "clicks"
      element_activity_units(@bars[:email], :plural => true).should == "emails"
      element_activity_units(@bars[:tweet_on_twitter], :plural => true).should == "tweets"
      element_activity_units(@bars[:follow_on_twitter], :plural => true).should == "followers"
      element_activity_units(@bars[:like_on_facebook], :plural => true).should == "likes"
      element_activity_units(@bars[:share_on_linkedin], :plural => true).should == "shares"
      element_activity_units(@bars[:plus_one_on_google_plus], :plural => true).should == "plus ones"
      element_activity_units(@bars[:pin_on_pinterest], :plural => true).should == "pins"
      element_activity_units(@bars[:follow_on_pinterest], :plural => true).should == "followers"
      element_activity_units(@bars[:share_on_buffer], :plural => true).should == "shares"
    end

    it "consolidates multiple bar types into a unit that makes sense for all" do
      other_traffic_bar = SiteElement.new(:element_subtype => "traffic")
      element_activity_units([other_traffic_bar, @bars[:traffic]]).should == "click"
      element_activity_units([other_traffic_bar, @bars[:traffic], @bars[:email]]).should == "action"
    end
  end
end
