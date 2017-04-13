require 'spec_helper'
require 'site_detector'

describe SiteDetector do
  it 'should detect a weebly install', :vcr do
    s = SiteDetector.new('http://www.a-weebly-example-site.com/')
    expect(s.site_type).to eq(:weebly)
  end

  it 'should detect a wordpress install', :vcr do
    s = SiteDetector.new('http://www.wordpress-example-site.io/')
    expect(s.site_type).to eq(:wordpress)
  end

  it 'should detect a shopify install', :vcr do
    s = SiteDetector.new('http://www.calmtheham.com/')
    expect(s.site_type).to eq(:shopify)
  end

  it 'should detect a squarespace install', :vcr do
    s = SiteDetector.new('http://blog.lyft.com/')
    expect(s.site_type).to eq(:squarespace)
  end

  it 'should detect a squarespace install', :vcr do
    s = SiteDetector.new('http://skipjacksnauticalliving.blogspot.com/')
    expect(s.site_type).to eq(:blogspot)
  end

  context "can't connect to their site" do
    it 'returns nil' do
      allow(HTTParty).to receive(:get).and_raise(SocketError)
      s = SiteDetector.new('http://abc.123.com/')
      expect(s.site_type).to be_nil
    end
  end
end
