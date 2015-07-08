require 'spec_helper'
require 'site_detector'

describe SiteDetector do
  it 'should detect a weebly install' do
    s = SiteDetector.new("http://www.a-weebly-example-site.com/")
    s.site_type.should == :weebly
  end

  it 'should detect a wordpress install' do
    s = SiteDetector.new("http://www.wordpress-example-site.io/")
    s.site_type.should == :wordpress
  end

  it 'should detect a shopify install' do
    s = SiteDetector.new("http://www.calmtheham.com/")
    s.site_type.should == :shopify
  end

  it 'should detect a squarespace install' do
    s = SiteDetector.new("http://blog.lyft.com/")
    s.site_type.should == :squarespace
  end
end
