require 'spec_helper'

describe ImproveSuggestion do
  fixtures :all

  # Takes a hash where the values are arrays of Model objects
  # and returns a hash where the values are arrays of sorted
  # model ids
  def sorted_ids(hash)
    results = {}
    hash.each do |key, values|
      results[key] = values.collect{|v| v.id}.sort
    end
    return results
  end

  before do
    @site = sites(:zombo)
    @traffic = site_elements(:zombo_traffic)
    @email = site_elements(:zombo_email)
    @twitter = site_elements(:zombo_twitter)
    @facebook = site_elements(:zombo_facebook)

    Hello::DataAPI.stub(suggested_opportunities: {
      "high traffic, low conversion" =>  [["co:USA", 100, 1], ["dv:Mobile", 200, 2], ["rf:http://zombo.com", 130, 4]],
      "low traffic, high conversion" =>  [["co:Russia", 10, 9], ["dv:Desktop", 22, 20], ["pu:http://zombo.com/signup", 5, 4]],
      "high traffic, high conversion" => [["co:China", 100, 30], ["ad_so:Google AdWords", 200, 55], ["co:Canada", 430, 120]]
    })
  end

  it "should return the site elements into groups for generation" do
    groups = ImproveSuggestion.determine_groups(@site)

    sorted_ids(groups).should == sorted_ids({
      "all" => [@traffic, @email, @twitter, @facebook],
      "social" => [@twitter, @facebook],
      "email" => [@email],
      "traffic" => [@traffic],
      "announcement" => []
    })
  end

  it "should let you generate data for a site" do
    suggestion = ImproveSuggestion.generate(@site, "traffic", [@traffic])
    suggestion.should be_a(ImproveSuggestion)
    suggestion.updated_at.should be_within(2).of(Time.now)
    suggestion.name.should == "traffic"
    suggestion.id.should_not be_nil
  end

  it "should store actual data" do
    pending "a good way to test this against actual data API"
  end

  it "should generate all the data" do
    results = ImproveSuggestion.generate_all(@site)
    results.keys.sort.should == %w{all traffic email social}.sort
  end

  it "should not let you update the data too frequently" do
    suggestion = ImproveSuggestion.generate(@site, "traffic", [@traffic])
    suggestion.should be_a(ImproveSuggestion)
    ImproveSuggestion.generate(@site, "traffic", [@traffic]).should be_false
  end

  it "should update an existing improvement" do
    suggestion = ImproveSuggestion.generate(@site, "traffic", [@traffic])
    suggestion.updated_at.should be_within(2).of(Time.now)
    suggestion.updated_at -= ImproveSuggestion::MIN_UPDATE_TIME+5
    suggestion.save!
    suggestion = ImproveSuggestion.find(suggestion.id)
    (Time.now-suggestion.updated_at).should > ImproveSuggestion::MIN_UPDATE_TIME
    suggestion2 = ImproveSuggestion.generate(@site, "traffic", [@traffic])
    suggestion2.id.should == suggestion.id
    suggestion2.updated_at.should be_within(2).of(Time.now)
  end

  it "should get the data if it exists" do
    ImproveSuggestion.get(@site, "traffic").should == nil
    suggestion = ImproveSuggestion.generate(@site, "traffic", [@traffic])
    suggestion.data = {"foo"=>"bar"}
    suggestion.save!
    ImproveSuggestion.get(@site, "traffic").should == {"foo"=>"bar"}
  end

  it "should get_all the data if it exists" do
    ImproveSuggestion.get_all(@site, true).should == {}
    suggestion = ImproveSuggestion.generate(@site, "traffic", [@traffic])
    suggestion.data = {"foo"=>"bar"}
    suggestion.save!
    ImproveSuggestion.get_all(@site, true).should == {"traffic"=>{"foo"=>"bar"}}
  end
end
