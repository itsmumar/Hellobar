require 'spec_helper'

describe EmailDigestHelper do
  describe "bar_activity_units" do
    before(:each) do
      @bars = {
        :traffic =>                 Bar.new(:bar_type => "traffic"),
        :email =>                   Bar.new(:bar_type => "email"),
        :tweet_on_twitter =>        Bar.new(:bar_type => "social/tweet_on_twitter"),
        :follow_on_twitter =>       Bar.new(:bar_type => "social/follow_on_twitter"),
        :like_on_facebook =>        Bar.new(:bar_type => "social/like_on_facebook"),
        :share_on_linkedin =>       Bar.new(:bar_type => "social/share_on_linkedin"),
        :plus_one_on_google_plus => Bar.new(:bar_type => "social/plus_one_on_google_plus"),
        :pin_on_pinterest =>        Bar.new(:bar_type => "social/pin_on_pinterest"),
        :follow_on_pinterest =>     Bar.new(:bar_type => "social/follow_on_pinterest"),
        :share_on_buffer =>         Bar.new(:bar_type => "social/share_on_buffer")
      }
    end

    it "returns the correct units for all bar types" do
      bar_activity_units(@bars[:traffic]).should == "click"
      bar_activity_units(@bars[:email]).should == "email"
      bar_activity_units(@bars[:tweet_on_twitter]).should == "tweet"
      bar_activity_units(@bars[:follow_on_twitter]).should == "follower"
      bar_activity_units(@bars[:like_on_facebook]).should == "like"
      bar_activity_units(@bars[:share_on_linkedin]).should == "share"
      bar_activity_units(@bars[:plus_one_on_google_plus]).should == "plus one"
      bar_activity_units(@bars[:pin_on_pinterest]).should == "pin"
      bar_activity_units(@bars[:follow_on_pinterest]).should == "follower"
      bar_activity_units(@bars[:share_on_buffer]).should == "share"
    end

    # not sure we'll end up needing this. also, verb is awkward for a lot of bar types.
#     it "optionally adds an appropriate verb" do
#       bar_activity_units(@bars[:traffic], :verb => true).should == "click recorded"
#       bar_activity_units(@bars[:email], :verb => true).should == "email collected"
#       bar_activity_units(@bars[:tweet_on_twitter], :verb => true).should == "tweet"
#       bar_activity_units(@bars[:follow_on_twitter], :verb => true).should == "follow gained"
#       bar_activity_units(@bars[:like_on_facebook], :verb => true).should == "like"
#       bar_activity_units(@bars[:share_on_linkedin], :verb => true).should == "share"
#       bar_activity_units(@bars[:plus_one_on_google_plus], :verb => true).should == "plus one"
#       bar_activity_units(@bars[:pin_on_pinterest], :verb => true).should == "pin"
#       bar_activity_units(@bars[:follow_on_pinterest], :verb => true).should == "follow gained"
#       bar_activity_units(@bars[:share_on_buffer], :verb => true).should == "share"
#     end
#     it "adjusts the verb to make sense for multiple bars with different units"

    it "optionally pluralizes the units" do
      bar_activity_units(@bars[:traffic], :plural => true).should == "clicks"
      bar_activity_units(@bars[:email], :plural => true).should == "emails"
      bar_activity_units(@bars[:tweet_on_twitter], :plural => true).should == "tweets"
      bar_activity_units(@bars[:follow_on_twitter], :plural => true).should == "followers"
      bar_activity_units(@bars[:like_on_facebook], :plural => true).should == "likes"
      bar_activity_units(@bars[:share_on_linkedin], :plural => true).should == "shares"
      bar_activity_units(@bars[:plus_one_on_google_plus], :plural => true).should == "plus ones"
      bar_activity_units(@bars[:pin_on_pinterest], :plural => true).should == "pins"
      bar_activity_units(@bars[:follow_on_pinterest], :plural => true).should == "followers"
      bar_activity_units(@bars[:share_on_buffer], :plural => true).should == "shares"
    end

    it "consolidates multiple bar types into a unit that makes sense for all" do
      other_traffic_bar = Bar.new(:bar_type => "traffic")
      bar_activity_units([other_traffic_bar, @bars[:traffic]]).should == "click"
      bar_activity_units([other_traffic_bar, @bars[:traffic], @bars[:email]]).should == "action"
    end
  end
end
