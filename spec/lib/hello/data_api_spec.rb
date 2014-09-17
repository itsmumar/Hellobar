require "spec_helper"

describe Hello::DataAPI, '.lifetime_totals_by_type' do
  fixtures :all

  it "rolls up lifetime totals by site element type" do
    site = sites(:zombo)

    Hello::DataAPI.should_receive(:lifetime_totals).and_return({
      site_elements(:zombo_traffic).id.to_s =>  [[2, 1]],
      site_elements(:zombo_email).id.to_s =>    [[4, 3]],
      site_elements(:zombo_twitter).id.to_s =>  [[6, 5]],
      site_elements(:zombo_facebook).id.to_s => [[8, 7]]
    })

    result = Hello::DataAPI.lifetime_totals_by_type(site, site.site_elements)

    result.should == {
      :total =>   [[20, 16]],
      :traffic => [[2, 1]],
      :email =>   [[4, 3]],
      :social =>  [[14, 12]]
    }
  end

  it "when site elements have different amounts of data, use all of it" do
    site = sites(:zombo)

    Hello::DataAPI.should_receive(:lifetime_totals).and_return({
      site_elements(:zombo_traffic).id.to_s =>  [[2, 1]],
      site_elements(:zombo_email).id.to_s =>    [[4, 3]],
      site_elements(:zombo_twitter).id.to_s =>  [[3, 1], [6, 5]],
      site_elements(:zombo_facebook).id.to_s => [[8, 7]]
    })

    result = Hello::DataAPI.lifetime_totals_by_type(site, site.site_elements)

    result.should == {
      :total =>   [[3, 1], [20, 16]],
      :traffic => [[2, 1]],
      :email =>   [[4, 3]],
      :social =>  [[3, 1], [14, 12]]
    }
  end

  it "returns empty totals if there's no data" do
    site = sites(:zombo)

    Hello::DataAPI.should_receive(:lifetime_totals).and_return({})

    result = Hello::DataAPI.lifetime_totals_by_type(site, site.site_elements)
    result.should == {:total =>   [], :traffic => [], :email =>   [], :social =>  []}
  end
end
