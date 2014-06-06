require 'spec_helper'

describe Site do
  fixtures :all

  it_behaves_like "an object with a valid url"

  it "is able to access its owner" do
    sites(:zombo).owner.should == users(:joey)
  end

  describe "url formatting" do
    it "adds the protocol if not present" do
      site = Site.new(:url => "zombo.com")
      site.valid?
      site.url.should == "http://zombo.com"
    end

    it "uses the supplied protocol if present" do
      site = Site.new(:url => "https://zombo.com")
      site.valid?
      site.url.should == "https://zombo.com"

      site = Site.new(:url => "http://zombo.com")
      site.valid?
      site.url.should == "http://zombo.com"
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
        site.url.should == "http://zombo.com"
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
        site.errors[:url].should be_empty
      end
    end
  end
end
