require 'spec_helper'

describe SiteElementActivityMessagesHelper do
  fixtures :all

  describe "#helper.activity_message" do
    context "with no conversions" do
      it "is silent for traffic elements" do
        element = site_elements(:zombo_traffic)
        element.stub(:total_conversions => 0, :total_views => 0)
        expect(helper.activity_message(element)).to be_nil
      end

      it "is silent for email elements" do
        element = site_elements(:zombo_email)
        element.stub(:total_conversions => 0, :total_views => 0)
        expect(helper.activity_message(element)).to be_nil
      end

      it "is silent for twitter elements" do
        element = site_elements(:zombo_twitter)
        element.stub(:total_conversions => 0, :total_views => 0)
        expect(helper.activity_message(element)).to be_nil
      end

      it "is silent for facebook elements" do
        element = site_elements(:zombo_facebook)
        element.stub(:total_conversions => 0, :total_views => 0)
        expect(helper.activity_message(element)).to be_nil
      end
    end

    it "doesn't pluralize when there was only one conversion" do
      element = site_elements(:zombo_email)
      element.stub(:total_conversions => 1, :total_views => 1)
      helper.activity_message(element).should =~ /resulted in 1 email collected/
    end

    context "with multiple conversions" do
      it "returns the correct message for traffic elements" do
        element = site_elements(:zombo_traffic)
        element.stub(:total_conversions => 5, :total_views => 5)
        helper.activity_message(element).should =~ /resulted in 5 clicks/
      end

      it "returns the correct message for email elements" do
        element = site_elements(:zombo_email)
        element.stub(:total_conversions => 5, :total_views => 5)
        helper.activity_message(element).should =~ /resulted in 5 emails collected/
      end

      it "returns the correct message for twitter elements" do
        Hello::DataAPI.stub(:lifetime_totals => {})
        element = site_elements(:zombo_twitter)
        element.stub(:total_conversions => 5, :total_views => 5)
        helper.activity_message(element).should =~ /resulted in 5 tweets/
      end

      it "returns the correct message for facebook elements" do
        Hello::DataAPI.stub(:lifetime_totals => {})
        element = site_elements(:zombo_facebook)
        element.stub(:total_conversions => 5, :total_views => 5)
        helper.activity_message(element).should =~ /resulted in 5 likes/
      end
    end

    it "shows the conversion rate relative to other elements of the same type" do
      element = site_elements(:zombo_twitter)
      Hello::DataAPI.stub(:lifetime_totals => {
        element.id.to_s => Hello::DataAPI::Performance.new([[10, 5]]),
        site_elements(:zombo_facebook).id.to_s => Hello::DataAPI::Performance.new([[10, 1]])
      })

      helper.activity_message(element).should =~ /converting 400\.0% better than your other social bars/
    end

    it "doesn't show a percentage when comparing against other bars with no conversions" do
      element = site_elements(:zombo_twitter)
      Hello::DataAPI.stub(:lifetime_totals => {
        element.id.to_s => Hello::DataAPI::Performance.new([[10, 5]]),
        site_elements(:zombo_facebook).id.to_s => Hello::DataAPI::Performance.new([[10, 0]])
      })

      helper.activity_message(element).should =~ /converting better than your other social bars/
    end

    it "doesnt return the conversion rate when it is Infinite" do
      element = site_elements(:zombo_twitter)
      Hello::DataAPI.stub(:lifetime_totals => {
        element.id.to_s => Hello::DataAPI::Performance.new([[0, 5]]),
        site_elements(:zombo_facebook).id.to_s => Hello::DataAPI::Performance.new([[10, 1]])
      })

      helper.activity_message(element).should_not =~ /Currently this bar is converting/
    end
  end

end
