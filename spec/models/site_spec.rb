require 'spec_helper'

describe Site do
  fixtures :all

  before(:each) do
    @site = sites(:zombo)
  end

  it_behaves_like "an object with a valid url"

  it "is able to access its owner" do
    @site.owner.should == users(:joey)
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

  describe "#script_content" do
    it "generates the contents of the script for a site" do
      script = @site.script_content(false)

      script.should =~ /HB_SITE_ID/
      script.should include(@site.site_elements.first.id.to_s)
    end

    it "generates the compressed contents of the script for a site" do
      script = @site.script_content

      script.should =~ /HB_SITE_ID/
      script.should include(@site.site_elements.first.id.to_s)
    end
  end

  describe "#generate_static_assets" do
    it "generates and uploads the script content for a site" do
      script_content = @site.script_content(true)
      script_name = @site.script_name

      mock_storage = double("asset_storage")
      mock_storage.should_receive(:create_or_update_file_with_contents).with(script_name, script_content)
      Hello::AssetStorage.stub(:new => mock_storage)

      @site.generate_script
    end
  end

  it "blanks-out the site script when destroyed" do
    mock_storage = double("asset_storage")
    mock_storage.should_receive(:create_or_update_file_with_contents).with(@site.script_name, "")
    Hello::AssetStorage.stub(:new => mock_storage)

    @site.destroy
  end

  describe "#has_script_installed?" do
    it "is true if script_installed_at is set" do
      @site.script_installed_at = 1.day.ago
      @site.has_script_installed?.should be_true
    end

    it "is false if no site_elements have views" do
      @site.stub(:site_elements => [double("bar", :total_views => 0)])
      @site.has_script_installed?.should be_false
      @site.script_installed_at.should be_nil
    end

    it "is true and sets script_installed_at if at least one site_element has been viewed" do
      @site.stub(:site_elements => [double("bar", :total_views => 1)])
      @site.has_script_installed?.should be_true
      @site.script_installed_at.should_not be_nil
    end
  end
end
